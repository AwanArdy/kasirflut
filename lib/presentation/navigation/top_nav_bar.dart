import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/local/app_database.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/catalog/catalog_cubit.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../logic/update/update_cubit.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/offline_queue_modal.dart';
import '../widgets/settings_modal.dart';
import '../widgets/shift_modals.dart';

class TopNavBar extends StatelessWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final outletName = authState is AuthAuthenticated
        ? authState.session.outletName
        : 'Outlet Utama';
    final cashierName = authState is AuthAuthenticated
        ? authState.session.userName
        : 'Kasir';

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHigh, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Brand Identity
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.point_of_sale_rounded,
              color: AppColors.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TERATUR POS',
                style: AppTypography.headlineSm.copyWith(
                  fontSize: 17,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  height: 1.15,
                ),
              ),
              Text(
                'POINT OF SALE',
                style: AppTypography.labelXs.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Status Pills (Scrollable on narrow screens)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Outlet Pill
                  _StatusPill(
                    backgroundColor: AppColors.surfaceContainerLow,
                    icon: Icons.store_rounded,
                    iconColor: AppColors.primary,
                    text: outletName,
                    textColor: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(width: 8),

                  // Shift Pill
                  BlocBuilder<ShiftCubit, ShiftState>(
                    builder: (context, state) {
                      if (state is ShiftActive) {
                        return _StatusPill(
                          backgroundColor: AppColors.surfaceContainer,
                          leadingDotColor: AppColors.primaryStrong,
                          text:
                              'Shift Aktif • Kas: ${formatRupiah(state.session.expectedCashIdr)}',
                          textColor: AppColors.primaryStrong,
                          fontWeight: FontWeight.w600,
                        );
                      }
                      return _StatusPill(
                        backgroundColor: AppColors.warningBg,
                        icon: Icons.schedule_rounded,
                        iconColor: AppColors.warningText,
                        text: 'Shift Belum Dibuka',
                        textColor: AppColors.warningText,
                        fontWeight: FontWeight.w600,
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Offline Queue Pill
                  FutureBuilder<int>(
                    future: AppDatabase.instance.getPendingTransactionCount(),
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.data ?? 0;
                      final hasPending = pendingCount > 0;
                      return InkWell(
                        onTap: () => showOfflineQueueModal(context),
                        borderRadius: BorderRadius.circular(999),
                        child: _StatusPill(
                          backgroundColor: hasPending
                              ? AppColors.warningBg
                              : AppColors.surfaceContainerLow,
                          icon: hasPending
                              ? Icons.cloud_off_rounded
                              : Icons.cloud_done_rounded,
                          iconColor: hasPending
                              ? AppColors.warningText
                              : AppColors.primaryStrong,
                          text: hasPending
                              ? 'Offline ($pendingCount) • Antre Sync'
                              : 'Tersinkron',
                          textColor: hasPending
                              ? AppColors.warningText
                              : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Navigation & Action Group
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Active POS Tab Indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.point_of_sale_rounded,
                      size: 18,
                      color: AppColors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Kasir POS',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Riwayat Transaksi / Sync
              _NavGhostButton(
                icon: Icons.receipt_long_rounded,
                label: 'Riwayat',
                onTap: () => showOfflineQueueModal(context),
              ),
              const SizedBox(width: 4),

              // Buka / Tutup Shift
              BlocBuilder<ShiftCubit, ShiftState>(
                builder: (context, shiftState) {
                  final isOpen = shiftState is ShiftActive;
                  return _NavGhostButton(
                    icon: isOpen
                        ? Icons.lock_clock_rounded
                        : Icons.schedule_rounded,
                    label: isOpen ? 'Tutup Shift' : 'Buka Shift',
                    accentColor: isOpen ? AppColors.errorStrong : null,
                    onTap: () {
                      if (isOpen) {
                        showCloseShiftDialog(context, shiftState.session);
                      } else {
                        showOpenShiftDialog(context);
                      }
                    },
                  );
                },
              ),
              const SizedBox(width: 4),

              // Refresh Menu
              _NavGhostButton(
                icon: Icons.sync_rounded,
                label: 'Refresh',
                onTap: () => context.read<CatalogCubit>().fetchCatalog(),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Cashier Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    cashierName.isNotEmpty
                        ? cashierName[0].toUpperCase()
                        : 'K',
                    style: AppTypography.labelXs.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  cashierName,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Settings + Update Badge
          BlocBuilder<UpdateCubit, UpdateState>(
            builder: (context, updateState) {
              final hasUpdate = updateState is UpdateAvailable;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => showSettingsModal(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (hasUpdate)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),

          // Logout Button (Danger Tint)
          Material(
            color: AppColors.dangerBg,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => context.read<AuthCubit>().logout(),
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.errorStrong,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color backgroundColor;
  final IconData? icon;
  final Color? iconColor;
  final Color? leadingDotColor;
  final String text;
  final Color textColor;
  final FontWeight fontWeight;

  const _StatusPill({
    required this.backgroundColor,
    this.icon,
    this.iconColor,
    this.leadingDotColor,
    required this.text,
    required this.textColor,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: leadingDotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: AppTypography.labelSm.copyWith(
              color: textColor,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavGhostButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? accentColor;
  final VoidCallback onTap;

  const _NavGhostButton({
    required this.icon,
    required this.label,
    this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
