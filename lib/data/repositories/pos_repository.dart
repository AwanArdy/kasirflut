import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/storage/session_storage.dart';
import '../local/app_database.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/shift_model.dart';
import '../models/transaction_model.dart';

class CatalogFetchResult {
  final List<ProductModel> products;
  final bool fromOfflineCache;

  CatalogFetchResult({
    required this.products,
    required this.fromOfflineCache,
  });
}

class PosRepository {
  final ApiClient apiClient;
  final AppDatabase db;
  final SessionStorage sessionStorage;

  PosRepository({
    required this.apiClient,
    AppDatabase? db,
    SessionStorage? sessionStorage,
  })  : db = db ?? AppDatabase.instance,
        sessionStorage = sessionStorage ?? SessionStorage();

  // ==================== CATALOG ====================

  Future<CatalogFetchResult> fetchMenu() async {
    try {
      final res = await apiClient.get(
        '/pos/menu',
        queryParameters: {'page': 1, 'limit': 100},
      );
      final rawList = (res['data'] as List? ?? []);
      final products = rawList
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .where((p) => p.isActive)
          .toList();

      await db.replaceAllProducts(products);
      return CatalogFetchResult(products: products, fromOfflineCache: false);
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final cached = await db.getProducts();
        if (cached.isNotEmpty) {
          return CatalogFetchResult(products: cached, fromOfflineCache: true);
        }
      }
      rethrow;
    } catch (_) {
      final cached = await db.getProducts();
      if (cached.isNotEmpty) {
        return CatalogFetchResult(products: cached, fromOfflineCache: true);
      }
      rethrow;
    }
  }

  // ==================== SHIFT ====================

  Future<ShiftModel?> getActiveShift() async {
    try {
      final res = await apiClient.get('/pos/active-shift');
      final data = res['data'];
      if (data == null) {
        // Check if there's an unsynced local open shift
        final local = await db.getActiveShift();
        if (local != null && local.syncStatus == 'pending_open') {
          return local;
        }
        return null;
      }
      final shift = ShiftModel.fromJson(data as Map<String, dynamic>);
      await db.upsertShift(shift);
      return shift;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        return await db.getActiveShift();
      }
      rethrow;
    } catch (_) {
      return await db.getActiveShift();
    }
  }

  Future<ShiftModel> openShift({
    required int startingCashIdr,
    required String shiftName,
    String? notes,
  }) async {
    try {
      final res = await apiClient.post(
        '/shifts/open',
        data: {
          'startingCashIdr': startingCashIdr,
          'shiftName': shiftName,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final shift = ShiftModel.fromJson(res['data'] as Map<String, dynamic>);
      await db.upsertShift(shift);
      return shift;
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;

      final existing = await db.getActiveShift();
      if (existing != null) {
        throw ApiException(
          message: 'Masih ada shift kasir yang aktif di perangkat ini.',
          code: 'SHIFT_ALREADY_OPEN',
        );
      }

      final session = await sessionStorage.getSession();
      final localId = 'local_${const Uuid().v4()}';
      final offlineShift = ShiftModel(
        id: localId,
        serverId: null,
        outletId: session?.outletId ?? 'offline-outlet',
        staffId: '',
        shiftName: shiftName,
        startingCashIdr: startingCashIdr,
        status: 'open',
        notes: notes,
        openedAt: DateTime.now(),
        syncStatus: 'pending_open',
      );
      await db.upsertShift(offlineShift);
      return offlineShift;
    }
  }

  Future<ShiftModel> closeShift({
    required int actualPhysicalCashIdr,
    String? notes,
  }) async {
    final active = await db.getActiveShift();
    if (active == null) {
      throw ApiException(
        message: 'Tidak ada shift aktif yang perlu ditutup',
        code: 'NOT_FOUND',
      );
    }

    try {
      // If shift was opened offline, we can't close on server until synced
      if (active.serverId != null) {
        final res = await apiClient.post(
          '/shifts/close',
          data: {
            'actualPhysicalCashIdr': actualPhysicalCashIdr,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          },
        );
        final closed =
            ShiftModel.fromJson(res['data'] as Map<String, dynamic>);
        await db.upsertShift(closed);
        return closed;
      }
    } on ApiException catch (e) {
      if (!e.isNetworkError) rethrow;
    }

    // Offline close
    final expectedCash = active.expectedCashIdr;
    final difference = actualPhysicalCashIdr - expectedCash;
    final status = difference == 0 ? 'balanced' : 'variance';
    final nextSyncStatus =
        active.syncStatus == 'pending_open' ? 'pending_open' : 'pending_close';

    final closedOffline = active.copyWith(
      actualPhysicalCashIdr: actualPhysicalCashIdr,
      differenceIdr: difference,
      notes: notes ?? active.notes,
      status: status,
      closedAt: DateTime.now(),
      syncStatus: nextSyncStatus,
    );
    await db.upsertShift(closedOffline);
    return closedOffline;
  }

  // ==================== CHECKOUT / SALES ====================

  Future<TransactionModel> createSale({
    required List<CartItemModel> items,
    required String orderType, // 'dine_in' | 'takeaway' | 'delivery'
    required String paymentMethod, // 'cash' | 'qris' | 'debit' | 'bank_transfer'
    required int discountIdr,
    required int taxIdr,
    required int amountReceivedIdr,
    String? customerName,
  }) async {
    final idempotencyKey = const Uuid().v4();
    final localId = const Uuid().v4();
    final now = DateTime.now();
    final activeShift = await db.getActiveShift();

    final subtotalIdr =
        items.fold<int>(0, (sum, item) => sum + item.subtotalIdr);
    final totalIdr = subtotalIdr + taxIdr - discountIdr;
    final changeIdr =
        paymentMethod == 'cash' && amountReceivedIdr > totalIdr
            ? amountReceivedIdr - totalIdr
            : 0;

    final localNota =
        'OFF-${DateFormat('yyyyMMdd-HHmmss').format(now)}-${localId.substring(0, 4).toUpperCase()}';

    final localTx = TransactionModel(
      id: localId,
      idempotencyKey: idempotencyKey,
      serverId: null,
      noNota: localNota,
      shiftId: activeShift?.id,
      orderType: orderType,
      paymentMethod: paymentMethod,
      customerName: customerName,
      subtotalIdr: subtotalIdr,
      discountIdr: discountIdr,
      taxIdr: taxIdr,
      totalIdr: totalIdr,
      amountReceivedIdr: amountReceivedIdr > 0 ? amountReceivedIdr : totalIdr,
      changeIdr: changeIdr,
      status: 'paid',
      items: items
          .map((e) => SaleItemSnapshot(
                productId: e.product.id,
                name: e.product.name,
                qty: e.quantity,
                unitPriceIdr: e.product.sellingPriceIdr,
                lineTotalIdr: e.subtotalIdr,
              ))
          .toList(),
      soldAt: now,
      syncStatus: 'pending',
    );

    // 1. Simpan ke SQLite terlebih dahulu (offline-first guarantee)
    await db.insertOrUpdateTransaction(localTx);

    // 2. Update akumulasi kas shift di SQLite
    if (activeShift != null) {
      await db.incrementShiftSales(
        shiftId: activeShift.id,
        paymentMethod: paymentMethod,
        totalIdr: totalIdr,
      );
    }

    // 3. Coba kirim ke backend PostgreSQL
    try {
      final res = await apiClient.post(
        '/pos/sales',
        idempotencyKey: idempotencyKey,
        data: localTx.toPosSalePayload(),
      );
      final serverData = res['data'] as Map<String, dynamic>;
      final syncedTx = TransactionModel.fromServerJson(
        serverData,
        idempotencyKey: idempotencyKey,
        localId: localId,
        shiftId: activeShift?.id,
        amountReceivedIdr: localTx.amountReceivedIdr,
        changeIdr: localTx.changeIdr,
      );
      await db.markTransactionSynced(
        localId: localId,
        serverId: syncedTx.serverId!,
        noNota: syncedTx.noNota,
      );
      return syncedTx;
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        // Offline mode: transaksi tetap sukses tersimpan di SQLite
        return localTx;
      }
      // Server validation error (misal stok habis)
      await db.markTransactionFailed(localId: localId, error: e.message);
      rethrow;
    }
  }
}
