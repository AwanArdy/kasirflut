import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../network/api_client.dart';
import '../network/api_exceptions.dart';
import '../../data/local/app_database.dart';

class SyncResult {
  final int syncedTransactions;
  final int failedTransactions;
  final int syncedShifts;

  SyncResult({
    this.syncedTransactions = 0,
    this.failedTransactions = 0,
    this.syncedShifts = 0,
  });
}

class SyncService {
  final ApiClient apiClient;
  final AppDatabase db;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isSyncing = false;

  SyncService({
    required this.apiClient,
    AppDatabase? db,
  }) : db = db ?? AppDatabase.instance;

  void startListening({void Function(SyncResult)? onSynced}) {
    _sub?.cancel();
    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final hasNetwork =
          results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        final result = await syncAll();
        onSynced?.call(result);
      }
    });
  }

  void dispose() {
    _sub?.cancel();
  }

  Future<SyncResult> syncAll() async {
    if (_isSyncing) return SyncResult();
    _isSyncing = true;

    int syncedShifts = 0;
    int syncedTx = 0;
    int failedTx = 0;

    try {
      // 1. Sync shifts yang dibuka/ditutup saat offline
      final pendingShifts = await db.getPendingShifts();
      for (final shift in pendingShifts) {
        try {
          if (shift.syncStatus == 'pending_open') {
            final openRes = await apiClient.post(
              '/shifts/open',
              data: {
                'startingCashIdr': shift.startingCashIdr,
                'shiftName': shift.shiftName,
                if (shift.notes != null && shift.notes!.isNotEmpty)
                  'notes': shift.notes,
              },
            );
            final serverId = openRes['data']['id'] as String;
            if (shift.closedAt != null &&
                shift.actualPhysicalCashIdr != null) {
              await apiClient.post(
                '/shifts/$serverId/close',
                data: {
                  'actualPhysicalCashIdr': shift.actualPhysicalCashIdr,
                  if (shift.notes != null && shift.notes!.isNotEmpty)
                    'notes': shift.notes,
                },
              );
            }
            await db.markShiftSynced(
              localId: shift.id,
              serverId: serverId,
              newSyncStatus: 'synced',
            );
            syncedShifts++;
          } else if (shift.syncStatus == 'pending_close' &&
              shift.serverId != null &&
              shift.actualPhysicalCashIdr != null) {
            await apiClient.post(
              '/shifts/${shift.serverId}/close',
              data: {
                'actualPhysicalCashIdr': shift.actualPhysicalCashIdr,
                if (shift.notes != null && shift.notes!.isNotEmpty)
                  'notes': shift.notes,
              },
            );
            await db.markShiftSynced(
              localId: shift.id,
              serverId: shift.serverId!,
              newSyncStatus: 'synced',
            );
            syncedShifts++;
          }
        } on ApiException catch (e) {
          if (e.isNetworkError) break;
        }
      }

      // 2. Sync transaksi offline dengan Idempotency-Key yang sama
      final pendingTxs = await db.getPendingTransactions();
      for (final tx in pendingTxs) {
        try {
          final res = await apiClient.post(
            '/pos/sales',
            idempotencyKey: tx.idempotencyKey,
            data: tx.toPosSalePayload(),
          );
          final data = res['data'] as Map<String, dynamic>;
          await db.markTransactionSynced(
            localId: tx.id,
            serverId: data['id'] as String,
            noNota: data['noNota'] as String? ?? tx.noNota,
          );
          syncedTx++;
        } on ApiException catch (e) {
          if (e.isNetworkError) {
            break; // Masih offline, hentikan loop
          }
          await db.markTransactionFailed(localId: tx.id, error: e.message);
          failedTx++;
        }
      }
    } finally {
      _isSyncing = false;
    }

    return SyncResult(
      syncedTransactions: syncedTx,
      failedTransactions: failedTx,
      syncedShifts: syncedShifts,
    );
  }
}
