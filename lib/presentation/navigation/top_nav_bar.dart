import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/local/app_database.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/catalog/catalog_cubit.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/offline_queue_modal.dart';
import '../widgets/shift_modals.dart';

class TopNavBar extends StatelessWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeString = DateFormat('HH:mm').format(now);
    final authState = context.watch<AuthCubit>().state;
    final outletName = authState is AuthAuthenticated
        ? authState.session.outletName
        : 'Outlet Utama';
    final cashierName = authState is AuthAuthenticated
        ? authState.session.userName
        : 'Kasir';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.point_of_sale, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            'TERATUR',
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.primaryStrong,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const ShapeDecoration(
              color: AppColors.surfaceContainer,
              shape: StadiumBorder(),
            ),
            child: Text(
              outletName,
              style: AppTypography.labelSm,
            ),
          ),
          const SizedBox(width: 12),
          BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, state) {
              if (state is ShiftActive) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet,
                          size: 16, color: AppColors.onPrimaryContainer),
                      const SizedBox(width: 6),
                      Text(
                        'Kas: ${formatRupiah(state.session.expectedCashIdr)}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Shift Belum Dibuka',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.warningText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          FutureBuilder<int>(
            future: AppDatabase.instance.getPendingTransactionCount(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data ?? 0;
              return OutlinedButton.icon(
                onPressed: () => showOfflineQueueModal(context),
                icon: Icon(
                  pendingCount > 0 ? Icons.cloud_off : Icons.cloud_done_outlined,
                  size: 18,
                  color: pendingCount > 0
                      ? AppColors.warningText
                      : AppColors.primaryStrong,
                ),
                label: Text(
                  pendingCount > 0
                      ? 'Offline ($pendingCount)'
                      : 'Riwayat & Sync',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: pendingCount > 0
                      ? AppColors.warningText
                      : AppColors.onSurfaceVariant,
                  side: BorderSide(
                    color: pendingCount > 0
                        ? AppColors.warningText
                        : AppColors.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Refresh Menu',
            onPressed: () => context.read<CatalogCubit>().fetchCatalog(),
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Kasir: $cashierName', style: AppTypography.labelMd),
              Text(timeString, style: AppTypography.bodySm),
            ],
          ),
          const SizedBox(width: 16),
          BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, shiftState) {
              if (shiftState is ShiftActive) {
                return OutlinedButton.icon(
                  onPressed: () =>
                      showCloseShiftDialog(context, shiftState.session),
                  icon: const Icon(Icons.lock_clock,
                      size: 18, color: AppColors.errorStrong),
                  label: const Text('Tutup Shift'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorStrong,
                    side: const BorderSide(color: AppColors.errorStrong),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                );
              }
              return ElevatedButton.icon(
                onPressed: () => showOpenShiftDialog(context),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Buka Shift'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Keluar Akun',
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
