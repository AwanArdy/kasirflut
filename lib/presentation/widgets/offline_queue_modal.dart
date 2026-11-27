import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/sync/sync_service.dart';
import '../../data/local/app_database.dart';
import '../../data/models/transaction_model.dart';
import '../../logic/catalog/catalog_cubit.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../utils/currency_formatter.dart';
import 'payment_modal.dart';

Future<void> showOfflineQueueModal(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierColor: AppColors.onSurface.withValues(alpha: 0.42),
    builder: (dialogCtx) => _OfflineQueueDialog(parentContext: context),
  );
}

class _OfflineQueueDialog extends StatefulWidget {
  final BuildContext parentContext;
  const _OfflineQueueDialog({required this.parentContext});

  @override
  State<_OfflineQueueDialog> createState() => _OfflineQueueDialogState();
}

class _OfflineQueueDialogState extends State<_OfflineQueueDialog> {
  List<TransactionModel> _transactions = [];
  bool _loading = true;
  bool _syncing = false;
  bool _autoSyncEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await AppDatabase.instance.getRecentTransactions(limit: 30);
    if (mounted) {
      setState(() {
        _transactions = rows;
        _loading = false;
      });
    }
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final syncService = widget.parentContext.read<SyncService>();
    final result = await syncService.syncAll();
    if (widget.parentContext.mounted) {
      await widget.parentContext.read<CatalogCubit>().fetchCatalog();
      await widget.parentContext
          .read<ShiftCubit>()
          .loadActiveShift(silent: true);
    }
    await _load();
    if (mounted) {
      setState(() => _syncing = false);
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(
              'Sinkronisasi selesai: ${result.syncedTransactions} transaksi terkirim'
              '${result.failedTransactions > 0 ? ', ${result.failedTransactions} gagal' : ''}.',
            ),
            backgroundColor: result.failedTransactions > 0
                ? AppColors.errorStrong
                : AppColors.primaryStrong,
          ),
        );
      }
    }
  }

  String _formatPaymentLabel(String method) {
    switch (method) {
      case 'qris':
        return 'QRIS';
      case 'debit':
        return 'Kartu Debit';
      case 'bank_transfer':
        return 'Transfer Bank';
      default:
        return 'Tunai';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingList = _transactions
        .where((t) => t.syncStatus == 'pending' || t.syncStatus == 'failed')
        .toList();
    final pendingTotalIdr =
        pendingList.fold<int>(0, (sum, tx) => sum + tx.totalIdr);

    final syncedList =
        _transactions.where((t) => t.syncStatus == 'synced').toList();
    final lastSyncedLabel = syncedList.isNotEmpty
        ? '${DateFormat('HH:mm').format(syncedList.first.soldAt.toLocal())} WIB'
        : 'Belum ada';

    final latestFailed = _transactions
        .where((t) => t.syncError != null && t.syncError!.isNotEmpty)
        .firstOrNull;

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: pendingList.isNotEmpty
                          ? AppColors.warningBg
                          : AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      color: pendingList.isNotEmpty
                          ? AppColors.warningText
                          : AppColors.primaryStrong,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antrean Sinkronisasi SQLite',
                          style: AppTypography.headlineSm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pendingList.isNotEmpty
                              ? '${pendingList.length} transaksi tersimpan lokal & menunggu sinkronisasi ke cloud.'
                              : 'Semua transaksi lokal perangkat sudah tersinkron ke cloud.',
                          style: AppTypography.labelSm,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: pendingList.isNotEmpty
                          ? AppColors.warningBg
                          : AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: pendingList.isNotEmpty
                                ? AppColors.warningText
                                : AppColors.primaryStrong,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pendingList.isNotEmpty
                              ? '${pendingList.length} Antre'
                              : 'Tersinkron',
                          style: AppTypography.labelXs.copyWith(
                            color: pendingList.isNotEmpty
                                ? AppColors.warningText
                                : AppColors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Scrollable Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Local Database Diagnostic Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.storage_rounded,
                                    size: 17,
                                    color: AppColors.primaryStrong,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PENYIMPANAN LOKAL POS',
                                    style: AppTypography.labelXs.copyWith(
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'SQLite Lokal • ${_transactions.length} Riwayat',
                                style: AppTypography.labelXs,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      pendingList.isNotEmpty
                                          ? Icons.pending_actions_rounded
                                          : Icons.check_circle_rounded,
                                      size: 20,
                                      color: pendingList.isNotEmpty
                                          ? AppColors.warningText
                                          : AppColors.primaryStrong,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        formatRupiah(pendingTotalIdr),
                                        style:
                                            AppTypography.headlineSm.copyWith(
                                          color: AppColors.primaryStrong,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '${pendingList.length} Transaksi Tertunda',
                                        style: AppTypography.labelXs,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Terakhir Sync Berhasil',
                                    style: AppTypography.labelXs,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lastSyncedLabel,
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RIWAYAT TRANSAKSI PERANGKAT',
                          style: AppTypography.labelXs.copyWith(
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          _autoSyncEnabled
                              ? 'Auto-retry aktif'
                              : 'Sinkronisasi manual',
                          style: AppTypography.labelXs,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Queue List
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (_transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 36,
                              color: AppColors.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada transaksi tersimpan di perangkat ini.',
                              style: AppTypography.bodySm,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final tx = _transactions[index];
                          final isPending = tx.syncStatus == 'pending';
                          final isFailed = tx.syncStatus == 'failed';

                          final badgeBg = isFailed
                              ? AppColors.dangerBg
                              : isPending
                                  ? AppColors.warningBg
                                  : AppColors.primaryContainer;
                          final badgeFg = isFailed
                              ? AppColors.errorStrong
                              : isPending
                                  ? AppColors.warningText
                                  : AppColors.onPrimaryContainer;
                          final badgeText = isFailed
                              ? 'Gagal Sync'
                              : isPending
                                  ? 'Antre Sync'
                                  : 'Tersinkron';

                          final itemSummary = tx.items
                              .take(2)
                              .map((e) => '${e.name} x${e.qty}')
                              .join(', ');
                          final extraCount = tx.items.length > 2
                              ? ' +${tx.items.length - 2} lainnya'
                              : '';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 6,
                                            children: [
                                              Text(
                                                tx.noNota,
                                                style: AppTypography.labelMd
                                                    .copyWith(
                                                  letterSpacing: 0,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                '• ${DateFormat('dd/MM HH:mm').format(tx.soldAt.toLocal())} WIB',
                                                style: AppTypography.labelXs,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${tx.customerName?.isNotEmpty == true ? tx.customerName : 'Walk-in'} • ${tx.items.length} Items ($itemSummary$extraCount)',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.labelSm,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: AppTypography.labelXs.copyWith(
                                          color: badgeFg,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (tx.syncError != null &&
                                    tx.syncError!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Error: ${tx.syncError}',
                                    style: AppTypography.labelXs.copyWith(
                                      color: AppColors.errorStrong,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          formatRupiah(tx.totalIdr),
                                          style:
                                              AppTypography.headlineSm.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryStrong,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _formatPaymentLabel(
                                              tx.paymentMethod,
                                            ),
                                            style: AppTypography.labelXs,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => showReceiptModal(
                                            widget.parentContext,
                                            tx,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Detail',
                                              style: AppTypography.labelXs
                                                  .copyWith(
                                                color: AppColors.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isPending || isFailed) ...[
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: _syncing ? null : _syncNow,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    AppColors.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.send_rounded,
                                                    size: 13,
                                                    color: AppColors
                                                        .onPrimaryContainer,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Coba Kirim',
                                                    style: AppTypography.labelXs
                                                        .copyWith(
                                                      color: AppColors
                                                          .onPrimaryContainer,
                                                    ),
                                                  ),
                                                ],
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
                          );
                        },
                      ),

                    const SizedBox(height: 14),

                    // Auto-sync Toggle Row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.autorenew_rounded,
                            size: 20,
                            color: AppColors.primaryStrong,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sinkronisasi Otomatis',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Kirim otomatis saat koneksi internet perangkat pulih',
                                  style: AppTypography.labelXs,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _autoSyncEnabled,
                            activeColor: AppColors.onPrimary,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) =>
                                setState(() => _autoSyncEnabled = val),
                          ),
                        ],
                      ),
                    ),

                    if (latestFailed != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.terminal_rounded,
                              size: 16,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Log terakhir (${latestFailed.noNota}): ${latestFailed.syncError}',
                                style: AppTypography.labelXs.copyWith(
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // 3. Footer Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _loading ? null : _load,
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerLow,
                      foregroundColor: AppColors.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Muat Ulang'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _syncing ? null : _syncNow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Icon(Icons.sync_rounded, size: 20),
                      label: Text(
                        _syncing
                            ? 'Menyinkronkan...'
                            : pendingList.isNotEmpty
                                ? 'Sinkronkan Semua (${pendingList.length})'
                                : 'Sinkronkan Sekarang',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
