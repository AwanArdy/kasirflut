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
    final cashierInitial =
        cashierName.isNotEmpty ? cashierName[0].toUpperCase() : 'K';

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo & Name
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: AppColors.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TERATUR',
                style: AppTypography.headlineSm.copyWith(
                  color: AppColors.primaryStrong,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                'Point of Sale',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Outlet Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  size: 15,
                  color: AppColors.primaryStrong,
                ),
                const SizedBox(width: 6),
                Text(
                  outletName,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Shift Status Pill
          BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, state) {
              if (state is ShiftActive) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryStrong,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 15,
                        color: AppColors.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kas: ${formatRupiah(state.session.expectedCashIdr)}',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.warningText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Shift Belum Dibuka',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.warningText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Spacer(),

          // Offline Queue / Sync Status Button
          FutureBuilder<int>(
            future: AppDatabase.instance.getPendingTransactionCount(),
            builder: (context, snapshot) {
              final pendingCount = snapshot.data ?? 0;
              final hasPending = pendingCount > 0;
              return OutlinedButton.icon(
                onPressed: () => showOfflineQueueModal(context),
                icon: Icon(
                  hasPending
                      ? Icons.cloud_off_rounded
                      : Icons.cloud_done_rounded,
                  size: 18,
                  color: hasPending
                      ? AppColors.warningText
                      : AppColors.primaryStrong,
                ),
                label: Text(
                  hasPending ? 'Offline ($pendingCount)' : 'Riwayat & Sync',
                  style: AppTypography.labelSm.copyWith(
                    color: hasPending
                        ? AppColors.warningText
                        : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: hasPending
                      ? AppColors.warningBg
                      : AppColors.surfaceContainerLow,
                  side: BorderSide(
                    color: hasPending
                        ? AppColors.warningText.withValues(alpha: 0.4)
                        : AppColors.outlineVariant,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Refresh Catalog
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: IconButton(
              tooltip: 'Refresh Menu',
              onPressed: () => context.read<CatalogCubit>().fetchCatalog(),
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),

          // Cashier Profile Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    cashierInitial,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cashierName,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timeString,
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Open / Close Shift Action
          BlocBuilder<ShiftCubit, ShiftState>(
            builder: (context, shiftState) {
              if (shiftState is ShiftActive) {
                return OutlinedButton.icon(
                  onPressed: () =>
                      showCloseShiftDialog(context, shiftState.session),
                  icon: const Icon(
                    Icons.lock_clock_rounded,
                    size: 17,
                    color: AppColors.errorStrong,
                  ),
                  label: const Text('Tutup Shift'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorStrong,
                    backgroundColor: AppColors.dangerBg,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
              return ElevatedButton.icon(
                onPressed: () => showOpenShiftDialog(context),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Buka Shift'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: IconButton(
              tooltip: 'Keluar Akun',
              onPressed: () => context.read<AuthCubit>().logout(),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
