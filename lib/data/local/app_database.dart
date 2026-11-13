import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import '../models/shift_model.dart';
import '../models/transaction_model.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'teratur_pos_offline.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            sku TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            selling_price_idr INTEGER NOT NULL,
            kind TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            image_url TEXT,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE shifts (
            id TEXT PRIMARY KEY,
            server_id TEXT,
            outlet_id TEXT NOT NULL,
            staff_id TEXT NOT NULL DEFAULT '',
            shift_name TEXT NOT NULL,
            starting_cash_idr INTEGER NOT NULL,
            cash_sales_idr INTEGER NOT NULL DEFAULT 0,
            qris_sales_idr INTEGER NOT NULL DEFAULT 0,
            actual_physical_cash_idr INTEGER,
            difference_idr INTEGER,
            notes TEXT,
            status TEXT NOT NULL,
            opened_at TEXT NOT NULL,
            closed_at TEXT,
            sync_status TEXT NOT NULL DEFAULT 'synced'
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            idempotency_key TEXT NOT NULL UNIQUE,
            server_id TEXT,
            no_nota TEXT NOT NULL,
            shift_id TEXT,
            order_type TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            customer_name TEXT,
            subtotal_idr INTEGER NOT NULL,
            discount_idr INTEGER NOT NULL DEFAULT 0,
            tax_idr INTEGER NOT NULL DEFAULT 0,
            total_idr INTEGER NOT NULL,
            amount_received_idr INTEGER NOT NULL DEFAULT 0,
            change_idr INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'paid',
            items_json TEXT NOT NULL,
            sold_at TEXT NOT NULL,
            sync_status TEXT NOT NULL DEFAULT 'pending',
            sync_error TEXT
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_transactions_sync ON transactions(sync_status, sold_at)',
        );
        await db.execute(
          'CREATE INDEX idx_shifts_status ON shifts(status, sync_status)',
        );
      },
    );
  }

  // ==================== PRODUCTS ====================

  Future<void> replaceAllProducts(List<ProductModel> products) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('products');
      for (final p in products) {
        await txn.insert(
          'products',
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<ProductModel>> getProducts() async {
    final db = await database;
    final rows = await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'category ASC, name ASC',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  // ==================== SHIFTS ====================

  Future<void> upsertShift(ShiftModel shift) async {
    final db = await database;
    await db.insert(
      'shifts',
      shift.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ShiftModel?> getActiveShift() async {
    final db = await database;
    final rows = await db.query(
      'shifts',
      where: "status = 'open'",
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ShiftModel.fromMap(rows.first);
  }

  Future<List<ShiftModel>> getPendingShifts() async {
    final db = await database;
    final rows = await db.query(
      'shifts',
      where: "sync_status != 'synced'",
      orderBy: 'opened_at ASC',
    );
    return rows.map(ShiftModel.fromMap).toList();
  }

  Future<void> incrementShiftSales({
    required String shiftId,
    required String paymentMethod,
    required int totalIdr,
  }) async {
    final db = await database;
    if (paymentMethod == 'cash') {
      await db.rawUpdate(
        'UPDATE shifts SET cash_sales_idr = cash_sales_idr + ? WHERE id = ?',
        [totalIdr, shiftId],
      );
    } else if (paymentMethod == 'qris') {
      await db.rawUpdate(
        'UPDATE shifts SET qris_sales_idr = qris_sales_idr + ? WHERE id = ?',
        [totalIdr, shiftId],
      );
    }
  }

  Future<void> markShiftSynced({
    required String localId,
    required String serverId,
    required String newSyncStatus,
  }) async {
    final db = await database;
    await db.update(
      'shifts',
      {'server_id': serverId, 'sync_status': newSyncStatus},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // ==================== TRANSACTIONS ====================

  Future<void> insertOrUpdateTransaction(TransactionModel tx) async {
    final db = await database;
    await db.insert(
      'transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 50}) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      orderBy: 'sold_at DESC',
      limit: limit,
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getPendingTransactions() async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: "sync_status IN ('pending', 'failed')",
      orderBy: 'sold_at ASC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<int> getPendingTransactionCount() async {
    final db = await database;
    final res = await db.rawQuery(
      "SELECT COUNT(*) AS cnt FROM transactions WHERE sync_status IN ('pending', 'failed')",
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> markTransactionSynced({
    required String localId,
    required String serverId,
    required String noNota,
  }) async {
    final db = await database;
    await db.update(
      'transactions',
      {
        'server_id': serverId,
        'no_nota': noNota,
        'sync_status': 'synced',
        'sync_error': null,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> markTransactionFailed({
    required String localId,
    required String error,
  }) async {
    final db = await database;
    await db.update(
      'transactions',
      {
        'sync_status': 'failed',
        'sync_error': error,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }
}
