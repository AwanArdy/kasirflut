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

Future<void> showOfflineQueueModal(BuildContext context) async {
  await showDialog(
    context: context,
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
    setState(() => _syncing = true);
    final syncService = widget.parentContext.read<SyncService>();
    final result = await syncService.syncAll();
    await widget.parentContext.read<CatalogCubit>().fetchCatalog();
    await widget.parentContext.read<ShiftCubit>().loadActiveShift();
    await _load();
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(
            'Sinkronisasi selesai: ${result.syncedTransactions} transaksi terkirim'
            '${result.failedTransactions > 0 ? ', ${result.failedTransactions} gagal' : ''}.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.storage_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('Riwayat Lokal (SQLite)'),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _syncing ? null : _syncNow,
            icon: _syncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync, size: 18),
            label: Text(_syncing ? 'Sync...' : 'Sync Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 400,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _transactions.isEmpty
                ? const Center(child: Text('Belum ada transaksi di perangkat ini.'))
                : ListView.separated(
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final tx = _transactions[index];
                      Color badgeBg = AppColors.primaryContainer;
                      Color badgeFg = AppColors.onPrimaryContainer;
                      String badgeText = 'Synced';

                      if (tx.syncStatus == 'pending') {
                        badgeBg = AppColors.warningBg;
                        badgeFg = AppColors.warningText;
                        badgeText = 'Pending Offline';
                      } else if (tx.syncStatus == 'failed') {
                        badgeBg = AppColors.error.withValues(alpha: 0.12);
                        badgeFg = AppColors.errorStrong;
                        badgeText = 'Gagal Sync';
                      }

                      return ListTile(
                        dense: true,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tx.noNota,
                                style: AppTypography.labelMd.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                badgeText,
                                style: AppTypography.labelSm
                                    .copyWith(color: badgeFg),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${DateFormat('dd/MM HH:mm').format(tx.soldAt.toLocal())} · '
                          '${tx.paymentMethod.toUpperCase()} · '
                          '${tx.items.length} item'
                          '${tx.syncError != null ? '\nError: ${tx.syncError}' : ''}',
                          style: AppTypography.bodySm,
                        ),
                        trailing: Text(
                          formatRupiah(tx.totalIdr),
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
