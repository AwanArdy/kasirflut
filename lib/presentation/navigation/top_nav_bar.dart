import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../utils/currency_formatter.dart';

class TopNavBar extends StatelessWidget {
  const TopNavBar({super.key});

  @override
    Widget build(BuildContext context) {
      // TODO: implement build
      final now = DateTime.now();
      final timeString = DateFormat('HH:mm:ss').format(now);

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
                shape: StadiumBorder()
              ),
              child: Text(
                'Outlet Utama',
                style: AppTypography.labelSm,
              ),
            ),
            const SizedBox(width: 12),

            BlocBuilder<ShiftCubit, ShiftState>(
              builder: (context, state) {
                if (state is ShiftActive) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, size: 16, color: AppColors.onPrimaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          formatRupiah(state.session.openingCash),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const Spacer(),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Kasir: Budi', style: AppTypography.labelMd),
                Text(timeString, style: AppTypography.bodySm),
              ],
            ),
            const SizedBox(width: 24),

            OutlinedButton.icon(
              onPressed: () {
                // TODO: trigger modal tutup shift
              },
              icon: const Icon(Icons.logout, size: 18, color: AppColors.onSurfaceVariant),
              label: const Text('Tutup Sesi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                side: const BorderSide(color: AppColors.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }
}
