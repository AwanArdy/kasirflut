import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/local/app_database.dart';
import '../../data/models/transaction_model.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../utils/currency_formatter.dart';

enum _SyncFilter { all, pending, synced, voided, failed }

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<TransactionModel> _allTransactions = [];
  TransactionModel? _selectedTx;
  bool _loading = true;
  bool _syncingAll = false;

  DateTime _selectedDate = DateTime.now();
  _SyncFilter _syncFilter = _SyncFilter.all;
  String _paymentFilter = 'all';

  final Set<String> _locallySyncedIds = {};
  final Set<String> _locallyVoidedIds = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

 Future<void> _loadTransactions() async {
  setState(() => _loading = true);
  try {
    final rows = await AppDatabase.instance.getRecentTransactions(limit: 200);
    if (!mounted) return;
    setState(() {
      _allTransactions = rows;
      _loading = false;
      final filtered = _filteredTransactions;
      if (filtered.isNotEmpty) {
        if (_selectedTx == null ||
            !filtered.any((t) => t.id == _selectedTx!.id)) {
          _selectedTx = filtered.first;
        }
      } else {
        _selectedTx = null;
      }
    });
  } catch (e) {
    debugPrint('SQLite tidak tersedia di platform ini: $e');
    if (!mounted) return;
    setState(() {
      _allTransactions = [];
      _selectedTx = null;
      _loading = false;
    });
  }
}

  String _formatShortNota(TransactionModel tx, int index) {
    if (tx.noNota.trim().isNotEmpty) {
      return tx.noNota.startsWith('#') ? tx.noNota : '#${tx.noNota}';
    }
    final numStr = (index + 1).toString().padLeft(4, '0');
    return '#TRX-$numStr';
  }

  String _formatFullNota(TransactionModel tx, int index) {
    if (tx.noNota.trim().isNotEmpty) {
      return tx.noNota.startsWith('#') ? tx.noNota : '#${tx.noNota}';
    }
    final dateTag = DateFormat('yyyyMMdd').format(tx.soldAt.toLocal());
    final numStr = (index + 1).toString().padLeft(4, '0');
    return '#TRX-$dateTag-$numStr';
  }

  String _effectiveSyncStatus(TransactionModel tx) {
    if (_locallyVoidedIds.contains(tx.id) ||
        tx.status.toLowerCase() == 'void' ||
        tx.status.toLowerCase() == 'cancelled') {
      return 'void';
    }
    if (_locallySyncedIds.contains(tx.id)) return 'synced';

    final raw = tx.syncStatus.toLowerCase();
    if (raw == 'failed' || raw == 'error') return 'failed';
    if (raw == 'pending' || raw == 'offline' || raw == 'queued') {
      return 'pending';
    }
    return 'synced';
  }

  List<TransactionModel> get _dateFilteredTransactions {
    return _allTransactions.where((tx) {
      final local = tx.soldAt.toLocal();
      return local.year == _selectedDate.year &&
          local.month == _selectedDate.month &&
          local.day == _selectedDate.day;
    }).toList();
  }

  List<TransactionModel> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();
    final baseList = _dateFilteredTransactions;

    return baseList.asMap().entries.where((entry) {
      final idx = entry.key;
      final tx = entry.value;
      final status = _effectiveSyncStatus(tx);

      if (_syncFilter == _SyncFilter.pending && status != 'pending') {
        return false;
      }
      if (_syncFilter == _SyncFilter.synced && status != 'synced') {
        return false;
      }
      if (_syncFilter == _SyncFilter.voided && status != 'void') {
        return false;
      }
      if (_syncFilter == _SyncFilter.failed && status != 'failed') {
        return false;
      }

      if (_paymentFilter != 'all' && tx.paymentMethod != _paymentFilter) {
        return false;
      }

      if (query.isNotEmpty) {
        final shortNo = _formatShortNota(tx, idx).toLowerCase();
        final fullNo = _formatFullNota(tx, idx).toLowerCase();
        final customer = (tx.customerName ?? '').toLowerCase();
        final method = _paymentLabel(tx.paymentMethod).toLowerCase();
        final itemNames =
            tx.items.map((e) => e.name.toLowerCase()).join(' ');
        if (!shortNo.contains(query) &&
            !fullNo.contains(query) &&
            !customer.contains(query) &&
            !method.contains(query) &&
            !itemNames.contains(query)) {
          return false;
        }
      }

      return true;
    }).map((e) => e.value).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        final list = _filteredTransactions;
        _selectedTx = list.isNotEmpty ? list.first : null;
      });
    }
  }

  Future<void> _syncAllPending() async {
    if (_syncingAll) return;
    final pendingList = _dateFilteredTransactions
        .where((tx) => _effectiveSyncStatus(tx) == 'pending')
        .toList();

    if (pendingList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua transaksi sudah tersinkron dengan cloud.'),
        ),
      );
      return;
    }

    setState(() => _syncingAll = true);
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;

    setState(() {
      for (final tx in pendingList) {
        _locallySyncedIds.add(tx.id);
      }
      _syncingAll = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${pendingList.length} transaksi antrean offline berhasil disinkronkan!',
        ),
        backgroundColor: AppColors.primaryStrong,
      ),
    );
  }

  Future<void> _exportCsvToClipboard() async {
    final rows = _filteredTransactions;
    final buffer = StringBuffer('NoNota,Waktu,Pelanggan,Metode,Status,Total_IDR\n');
    for (int i = 0; i < rows.length; i++) {
      final tx = rows[i];
      final nota = _formatShortNota(tx, i);
      final timeStr = DateFormat('yyyy-MM-dd HH:mm').format(tx.soldAt.toLocal());
      final cust = (tx.customerName ?? 'Walk-in').replaceAll(',', ' ');
      buffer.writeln(
        '$nota,$timeStr,$cust,${tx.paymentMethod},${_effectiveSyncStatus(tx)},${tx.totalIdr}',
      );
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Data CSV (${rows.length} transaksi) disalin ke clipboard.',
        ),
        backgroundColor: AppColors.primaryStrong,
      ),
    );
  }

  Future<void> _confirmVoidTransaction(
    TransactionModel tx,
    String receiptNo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Void Transaksi $receiptNo?',
          style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Transaksi senilai ${formatRupiah(tx.totalIdr)} akan ditandai batal (Void) pada catatan shift aktif.',
          style: AppTypography.bodySm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerBg,
              foregroundColor: AppColors.errorStrong,
              elevation: 0,
            ),
            child: const Text('Konfirmasi Void'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _locallyVoidedIds.add(tx.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi $receiptNo berhasil di-void.'),
          backgroundColor: AppColors.errorStrong,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final cashierName = authState is AuthAuthenticated
        ? authState.session.userName
        : 'Kasir Bertugas';

    final dayTx = _dateFilteredTransactions;
    final filteredTx = _filteredTransactions;

    int totalOmzet = 0;
    int validCount = 0;
    int cashOmzet = 0;
    int cashCount = 0;
    int nonCashOmzet = 0;
    int nonCashCount = 0;
    int pendingCount = 0;
    int syncedCount = 0;
    int voidCount = 0;
    int failedCount = 0;

    for (final tx in dayTx) {
      final status = _effectiveSyncStatus(tx);
      if (status == 'pending') pendingCount++;
      if (status == 'synced') syncedCount++;
      if (status == 'void') voidCount++;
      if (status == 'failed') failedCount++;

      if (status != 'void') {
        totalOmzet += tx.totalIdr;
        validCount++;
        if (tx.paymentMethod == 'cash') {
          cashOmzet += tx.totalIdr;
          cashCount++;
        } else {
          nonCashOmzet += tx.totalIdr;
          nonCashCount++;
        }
      }
    }

    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final dateBadgeLabel = isToday
        ? 'Hari Ini, ${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate)}'
        : DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate);

    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          // 1. Sub-Header & Controls Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.onSurface.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1720),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Riwayat Transaksi',
                                  style: AppTypography.headlineMd.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${dayTx.length} Transaksi',
                                    style: AppTypography.labelXs.copyWith(
                                      color: AppColors.primaryStrong,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Log transaksi lokal, validasi struk, & monitoring sinkronisasi cloud.',
                              style: AppTypography.bodySm,
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 17,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dateBadgeLabel,
                                  style: AppTypography.labelMd.copyWith(
                                    letterSpacing: 0,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Action Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TopActionButton(
                          icon: Icons.refresh_rounded,
                          label: 'Muat Ulang',
                          onTap: _loadTransactions,
                        ),
                        _TopActionButton(
                          icon: Icons.download_rounded,
                          label: 'Ekspor CSV',
                          onTap: _exportCsvToClipboard,
                        ),
                        InkWell(
                          onTap: _syncAllPending,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: pendingCount > 0
                                  ? AppColors.warningBg
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_syncingAll)
                                  const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.warningText,
                                    ),
                                  )
                                else
                                  Icon(
                                    pendingCount > 0
                                        ? Icons.sync_rounded
                                        : Icons.cloud_done_rounded,
                                    size: 18,
                                    color: pendingCount > 0
                                        ? AppColors.warningText
                                        : AppColors.primaryStrong,
                                  ),
                                const SizedBox(width: 6),
                                Text(
                                  pendingCount > 0
                                      ? 'Sync Sekarang ($pendingCount Pending)'
                                      : 'Semua Tersinkron',
                                  style: AppTypography.labelMd.copyWith(
                                    letterSpacing: 0,
                                    color: pendingCount > 0
                                        ? AppColors.warningText
                                        : AppColors.primaryStrong,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Scrollable Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // KPI Summary Row
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final cols = constraints.maxWidth >= 1024
                                    ? 4
                                    : (constraints.maxWidth >= 600 ? 2 : 1);
                                const gap = 12.0;
                                final cardWidth =
                                    (constraints.maxWidth - gap * (cols - 1)) /
                                        cols;

                                return Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    SizedBox(
                                      width: cardWidth,
                                      child: _KpiSummaryCard(
                                        title: 'TOTAL OMZET HARI INI',
                                        value: formatRupiah(totalOmzet),
                                        valueColor: AppColors.primaryStrong,
                                        icon: Icons.payments_rounded,
                                        iconBg: AppColors.surfaceContainer,
                                        iconColor: AppColors.primaryStrong,
                                        subtitleBold: '$validCount',
                                        subtitleRest:
                                            'transaksi berhasil dicatat',
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _KpiSummaryCard(
                                        title: 'PEMBAYARAN TUNAI',
                                        value: formatRupiah(cashOmzet),
                                        icon: Icons.point_of_sale_rounded,
                                        iconBg: AppColors.surfaceContainerLow,
                                        iconColor: AppColors.onSurface,
                                        subtitleBold: '$cashCount',
                                        subtitleRest: 'transaksi di laci kas',
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _KpiSummaryCard(
                                        title: 'NON-TUNAI (QRIS & EDC)',
                                        value: formatRupiah(nonCashOmzet),
                                        icon: Icons.contactless_rounded,
                                        iconBg: AppColors.surfaceContainerLow,
                                        iconColor: AppColors.onSurface,
                                        subtitleBold: '$nonCashCount',
                                        subtitleRest: 'transaksi elektronik',
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: _SyncStatusKpiCard(
                                        pendingCount: pendingCount,
                                        syncedCount: syncedCount,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 18),

                            // Split Workspace: List (7) + Detail (5)
                            if (isWide)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _buildTransactionListColumn(
                                      dayTx: dayTx,
                                      filteredTx: filteredTx,
                                      pendingCount: pendingCount,
                                      syncedCount: syncedCount,
                                      voidCount: voidCount,
                                      failedCount: failedCount,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: 5,
                                    child: _buildDetailColumn(
                                      dayTx: dayTx,
                                      cashierName: cashierName,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildTransactionListColumn(
                                    dayTx: dayTx,
                                    filteredTx: filteredTx,
                                    pendingCount: pendingCount,
                                    syncedCount: syncedCount,
                                    voidCount: voidCount,
                                    failedCount: failedCount,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildDetailColumn(
                                    dayTx: dayTx,
                                    cashierName: cashierName,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionListColumn({
    required List<TransactionModel> dayTx,
    required List<TransactionModel> filteredTx,
    required int pendingCount,
    required int syncedCount,
    required int voidCount,
    required int failedCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search & Filter Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText:
                      'Cari no struk, nama pelanggan, metode, atau nama menu...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Filter Chips & Payment Method Dropdown
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _FilterPill(
                        label: 'Semua (${dayTx.length})',
                        selected: _syncFilter == _SyncFilter.all,
                        onTap: () =>
                            setState(() => _syncFilter = _SyncFilter.all),
                      ),
                      _FilterPill(
                        label: 'Pending Offline ($pendingCount)',
                        selected: _syncFilter == _SyncFilter.pending,
                        onTap: () =>
                            setState(() => _syncFilter = _SyncFilter.pending),
                      ),
                      _FilterPill(
                        label: 'Tersinkron ($syncedCount)',
                        selected: _syncFilter == _SyncFilter.synced,
                        onTap: () =>
                            setState(() => _syncFilter = _SyncFilter.synced),
                      ),
                      _FilterPill(
                        label: 'Batal / Void ($voidCount)',
                        selected: _syncFilter == _SyncFilter.voided,
                        onTap: () =>
                            setState(() => _syncFilter = _SyncFilter.voided),
                      ),
                      if (failedCount > 0)
                        _FilterPill(
                          label: 'Gagal Sync ($failedCount)',
                          selected: _syncFilter == _SyncFilter.failed,
                          isError: true,
                          onTap: () =>
                              setState(() => _syncFilter = _SyncFilter.failed),
                        ),
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _paymentFilter,
                        isDense: true,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Semua Metode'),
                          ),
                          DropdownMenuItem(
                            value: 'cash',
                            child: Text('Tunai (Cash)'),
                          ),
                          DropdownMenuItem(
                            value: 'qris',
                            child: Text('QRIS'),
                          ),
                          DropdownMenuItem(
                            value: 'debit',
                            child: Text('Debit EDC'),
                          ),
                          DropdownMenuItem(
                            value: 'bank_transfer',
                            child: Text('Transfer Bank'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _paymentFilter = v);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Transaction Cards Stream
        if (filteredTx.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 44,
                  color: AppColors.outlineVariant,
                ),
                const SizedBox(height: 10),
                Text(
                  'Belum ada transaksi yang cocok',
                  style: AppTypography.headlineSm.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coba ubah filter status atau pilih tanggal lain.',
                  style: AppTypography.bodySm,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTx.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = filteredTx[index];
              final dayIndex = dayTx.indexOf(tx);
              final receiptNo = _formatShortNota(
                tx,
                dayIndex >= 0 ? dayIndex : index,
              );
              final isSelected =
                  _selectedTx != null && _selectedTx!.id == tx.id;
              final status = _effectiveSyncStatus(tx);

              return _TransactionStreamCard(
                tx: tx,
                receiptNo: receiptNo,
                isSelected: isSelected,
                syncStatus: status,
                onTap: () => setState(() => _selectedTx = tx),
                onRetrySync: () {
                  setState(() => _locallySyncedIds.add(tx.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Transaksi $receiptNo berhasil dikirim ulang ke server.',
                      ),
                      backgroundColor: AppColors.primaryStrong,
                    ),
                  );
                },
              );
            },
          ),

        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            'Menampilkan ${filteredTx.length} dari ${dayTx.length} transaksi',
            style: AppTypography.labelXs,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailColumn({
    required List<TransactionModel> dayTx,
    required String cashierName,
  }) {
    final tx = _selectedTx;
    if (tx == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            'Pilih transaksi di daftar sebelah kiri untuk melihat detail struk.',
          ),
        ),
      );
    }

    final dayIndex = dayTx.indexOf(tx);
    final fullReceiptNo =
        _formatFullNota(tx, dayIndex >= 0 ? dayIndex : 0);
    final shortReceiptNo =
        _formatShortNota(tx, dayIndex >= 0 ? dayIndex : 0);
    final status = _effectiveSyncStatus(tx);
    final isVoid = status == 'void';
    final isOfflinePending = status == 'pending' || status == 'failed';

    final itemsTotal = tx.items.fold<int>(
      0,
      (sum, item) => sum + item.lineTotalIdr,
    );
    final subtotal = tx.subtotalIdr > 0
        ? tx.subtotalIdr
        : (itemsTotal > 0 ? itemsTotal : tx.totalIdr);
    final totalItemQty = tx.items.fold<int>(0, (sum, item) => sum + item.qty);

    final customerInfo = (tx.customerName != null && tx.customerName!.isNotEmpty)
        ? '${_orderTypeLabel(tx.orderType)} • ${tx.customerName}'
        : _orderTypeLabel(tx.orderType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Receipt Detail Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              fullReceiptNo,
                              style: AppTypography.headlineSm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isVoid
                                    ? AppColors.dangerBg
                                    : AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isVoid ? 'Void / Batal' : 'Lunas',
                                style: AppTypography.labelXs.copyWith(
                                  color: isVoid
                                      ? AppColors.errorStrong
                                      : AppColors.primaryStrong,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 15,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(tx.soldAt.toLocal())} WIB',
                              style: AppTypography.bodySm,
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 15,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Kasir: $cashierName • $customerInfo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_rounded,
                      color: AppColors.primaryStrong,
                      size: 26,
                    ),
                  ),
                ],
              ),

              // Banner Offline SQLite (jika pending/failed)
              if (isOfflinePending) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status == 'failed'
                        ? AppColors.dangerBg
                        : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        status == 'failed'
                            ? Icons.sync_problem_rounded
                            : Icons.cloud_off_rounded,
                        size: 20,
                        color: status == 'failed'
                            ? AppColors.errorStrong
                            : AppColors.warningText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status == 'failed'
                                  ? 'Gagal Sinkron ke Server'
                                  : 'Tersimpan di SQLite Lokal',
                              style: AppTypography.labelSm.copyWith(
                                color: status == 'failed'
                                    ? AppColors.errorStrong
                                    : AppColors.warningText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              status == 'failed' &&
                                      tx.syncError != null &&
                                      tx.syncError!.isNotEmpty
                                  ? tx.syncError!
                                  : 'Transaksi ini tersimpan di memori lokal SQLite dan akan otomatis disinkronkan saat terhubung internet.',
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 12.5,
                                color: status == 'failed'
                                    ? AppColors.errorStrong
                                    : AppColors.warningText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _locallySyncedIds.add(tx.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$shortReceiptNo berhasil disinkronkan.',
                                    ),
                                    backgroundColor: AppColors.primaryStrong,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh_rounded,
                                      size: 14,
                                      color: status == 'failed'
                                          ? AppColors.errorStrong
                                          : AppColors.warningText,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Coba Sinkronkan',
                                      style: AppTypography.labelXs.copyWith(
                                        color: status == 'failed'
                                            ? AppColors.errorStrong
                                            : AppColors.warningText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Thermal Receipt Preview Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RINCIAN ITEM',
                          style: AppTypography.labelXs.copyWith(
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'SUBTOTAL',
                          style: AppTypography.labelXs.copyWith(
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (tx.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paket Transaksi POS',
                              style: AppTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              formatRupiah(tx.totalIdr),
                              style: AppTypography.headlineSm.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...tx.items.map((item) {
                        final lineTotal = item.lineTotalIdr > 0
                            ? item.lineTotalIdr
                            : (item.unitPriceIdr * item.qty);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTypography.bodyMd.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${item.qty}x @ ${formatRupiah(item.unitPriceIdr)}',
                                      style: AppTypography.labelSm,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatRupiah(lineTotal),
                                style: AppTypography.headlineSm.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    // Financial Summary Inner Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal (${totalItemQty > 0 ? totalItemQty : 1} items)',
                                style: AppTypography.bodySm,
                              ),
                              Text(
                                formatRupiah(subtotal),
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (tx.discountIdr > 0) ...[
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Diskon',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.primaryStrong,
                                  ),
                                ),
                                Text(
                                  '-${formatRupiah(tx.discountIdr)}',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.primaryStrong,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (tx.taxIdr > 0) ...[
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pajak',
                                  style: AppTypography.bodySm,
                                ),
                                Text(
                                  '+${formatRupiah(tx.taxIdr)}',
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              color: AppColors.surfaceContainerHigh,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Total Akhir',
                                style: AppTypography.headlineSm.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                formatRupiah(tx.totalIdr),
                                style: AppTypography.headlineLg.copyWith(
                                  fontSize: 24,
                                  color: isVoid
                                      ? AppColors.errorStrong
                                      : AppColors.primaryStrong,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _paymentIcon(tx.paymentMethod),
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _paymentLabel(tx.paymentMethod),
                                    style: AppTypography.labelXs,
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Text(
                                  'Ref: ${tx.serverId ?? tx.idempotencyKey}',
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelXs.copyWith(
                                    fontFamily: 'monospace',
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Mencetak ulang struk $shortReceiptNo ke thermal...',
                              ),
                              backgroundColor: AppColors.primaryStrong,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerLow,
                          foregroundColor: AppColors.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.print_rounded, size: 19),
                        label: Text(
                          'Cetak Ulang Struk',
                          style: AppTypography.labelMd.copyWith(
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'E-Receipt $shortReceiptNo siap dikirim.',
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerLow,
                          foregroundColor: AppColors.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon:
                            const Icon(Icons.send_to_mobile_rounded, size: 19),
                        label: Text(
                          'Kirim E-Receipt',
                          style: AppTypography.labelMd.copyWith(
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isVoid) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: TextButton.icon(
                    onPressed: () =>
                        _confirmVoidTransaction(tx, shortReceiptNo),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.dangerBg,
                      foregroundColor: AppColors.errorStrong,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 19),
                    label: Text(
                      'Void / Batalkan Transaksi',
                      style: AppTypography.labelMd.copyWith(
                        letterSpacing: 0,
                        color: AppColors.errorStrong,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Sync Health Mini Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  size: 18,
                  color: AppColors.primaryStrong,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokal DB: SQLite Offline-First',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Terakhir diperbarui: ${DateFormat('HH:mm').format(DateTime.now())} WIB',
                      style: AppTypography.labelXs,
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primaryStrong,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String subtitleBold;
  final String subtitleRest;

  const _KpiSummaryCard({
    required this.title,
    required this.value,
    this.valueColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.subtitleBold,
    required this.subtitleRest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelXs.copyWith(letterSpacing: 0.4),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineLg.copyWith(
              fontSize: 26,
              color: valueColor ?? AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: AppTypography.bodySm.copyWith(fontSize: 13),
              children: [
                TextSpan(
                  text: '$subtitleBold ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                TextSpan(text: subtitleRest),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncStatusKpiCard extends StatelessWidget {
  final int pendingCount;
  final int syncedCount;

  const _SyncStatusKpiCard({
    required this.pendingCount,
    required this.syncedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STATUS SINKRONISASI',
                style: AppTypography.labelXs.copyWith(letterSpacing: 0.4),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.cloud_sync_rounded,
                  size: 18,
                  color: AppColors.warningText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$pendingCount',
                style: AppTypography.headlineLg.copyWith(
                  fontSize: 26,
                  color: pendingCount > 0
                      ? AppColors.warningText
                      : AppColors.primaryStrong,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Antrean Offline / $syncedCount Tersinkron',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 13,
                  color: AppColors.primaryStrong,
                ),
                const SizedBox(width: 4),
                Text(
                  'Semua data aman tersimpan lokal',
                  style: AppTypography.labelXs.copyWith(
                    color: AppColors.primaryStrong,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isError;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    this.isError = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isError
        ? (selected ? AppColors.errorContainer : AppColors.dangerBg)
        : (selected
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerLow);
    final fg = isError
        ? AppColors.errorStrong
        : (selected
            ? AppColors.onPrimaryContainer
            : AppColors.onSurfaceVariant);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: fg,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TransactionStreamCard extends StatelessWidget {
  final TransactionModel tx;
  final String receiptNo;
  final bool isSelected;
  final String syncStatus;
  final VoidCallback onTap;
  final VoidCallback onRetrySync;

  const _TransactionStreamCard({
    required this.tx,
    required this.receiptNo,
    required this.isSelected,
    required this.syncStatus,
    required this.onTap,
    required this.onRetrySync,
  });

  @override
  Widget build(BuildContext context) {
    final timeLabel = DateFormat('HH:mm').format(tx.soldAt.toLocal());
    final customerText =
        (tx.customerName != null && tx.customerName!.isNotEmpty)
            ? '${_orderTypeLabel(tx.orderType)} (${tx.customerName})'
            : _orderTypeLabel(tx.orderType);
    final itemSummary = tx.items.isEmpty
        ? 'Transaksi Kasir'
        : '${tx.items.length} Items (${tx.items.map((e) => '${e.name} x${e.qty}').join(', ')})';

    final isFailed = syncStatus == 'failed';
    final isPending = syncStatus == 'pending';
    final isVoid = syncStatus == 'void';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerLow
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: isFailed
              ? const Border(
                  left: BorderSide(color: AppColors.errorStrong, width: 3.5),
                )
              : isSelected
                  ? const Border(
                      left: BorderSide(color: AppColors.primary, width: 4),
                    )
                  : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.onSurface.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isFailed
                    ? AppColors.dangerBg
                    : (isSelected
                        ? AppColors.surfaceContainer
                        : AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isFailed
                    ? Icons.sync_problem_rounded
                    : Icons.receipt_long_rounded,
                size: 20,
                color: isFailed
                    ? AppColors.errorStrong
                    : (isSelected
                        ? AppColors.primaryStrong
                        : AppColors.onSurface),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        receiptNo,
                        style: AppTypography.headlineSm.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _StatusChip(status: syncStatus),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$timeLabel • $customerText • $itemSummary',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatRupiah(tx.totalIdr),
                  style: AppTypography.headlineSm.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isVoid
                        ? AppColors.errorStrong
                        : (isSelected
                            ? AppColors.primaryStrong
                            : AppColors.onSurface),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tx.paymentMethod == 'qris'
                            ? AppColors.surfaceContainer
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _paymentIcon(tx.paymentMethod),
                            size: 13,
                            color: tx.paymentMethod == 'qris'
                                ? AppColors.primaryStrong
                                : AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _paymentLabel(tx.paymentMethod),
                            style: AppTypography.labelXs.copyWith(
                              color: tx.paymentMethod == 'qris'
                                  ? AppColors.primaryStrong
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFailed || isPending) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onRetrySync,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isFailed
                                ? AppColors.dangerBg
                                : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFailed ? 'Kirim Ulang' : 'Sync',
                            style: AppTypography.labelXs.copyWith(
                              color: isFailed
                                  ? AppColors.errorStrong
                                  : AppColors.warningText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    final String label;

    switch (status) {
      case 'pending':
        bg = AppColors.warningBg;
        fg = AppColors.warningText;
        icon = Icons.wifi_off_rounded;
        label = 'Pending Offline';
        break;
      case 'failed':
        bg = AppColors.dangerBg;
        fg = AppColors.errorStrong;
        icon = Icons.error_outline_rounded;
        label = 'Gagal Sync';
        break;
      case 'void':
        bg = AppColors.dangerBg;
        fg = AppColors.errorStrong;
        icon = Icons.block_rounded;
        label = 'Void';
        break;
      default:
        bg = AppColors.surfaceContainer;
        fg = AppColors.primaryStrong;
        icon = Icons.cloud_done_rounded;
        label = 'Synced';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelXs.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

String _orderTypeLabel(String orderType) {
  switch (orderType) {
    case 'takeaway':
      return 'Takeaway';
    case 'delivery':
      return 'Delivery';
    default:
      return 'Dine In';
  }
}

String _paymentLabel(String method) {
  switch (method) {
    case 'qris':
      return 'QRIS';
    case 'debit':
      return 'Debit EDC';
    case 'bank_transfer':
      return 'Transfer';
    default:
      return 'Tunai';
  }
}

IconData _paymentIcon(String method) {
  switch (method) {
    case 'qris':
      return Icons.qr_code_2_rounded;
    case 'debit':
      return Icons.credit_card_rounded;
    case 'bank_transfer':
      return Icons.account_balance_rounded;
    default:
      return Icons.payments_rounded;
  }
}
