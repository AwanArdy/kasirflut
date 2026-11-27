import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/release_info_model.dart';
import '../../logic/update/update_cubit.dart';

class UpdateDialog extends StatelessWidget {
  final ReleaseInfo release;
  final VoidCallback? onOpenSettings;

  const UpdateDialog({
    super.key,
    required this.release,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) {
        final isDownloading = state is UpdateDownloading;
        final progress = isDownloading ? state.progress : 0.0;

        return Dialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: AppColors.primaryStrong,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Update Aplikasi Tersedia',
                              style: AppTypography.headlineSm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Versi baru v${release.version} siap dipasang',
                              style: AppTypography.labelSm,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATATAN PEMBARUAN',
                          style: AppTypography.labelXs.copyWith(
                            color: AppColors.primaryStrong,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 160),
                          child: SingleChildScrollView(
                            child: Text(
                              release.notes.isNotEmpty
                                  ? release.notes
                                  : 'Perbaikan performa dan stabilitas aplikasi.',
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Jika outlet sedang ramai, kamu bisa menutup pesan ini dan melakukan update nanti lewat menu Pengaturan.',
                    style: AppTypography.labelSm,
                  ),

                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: progress > 0 ? progress : null,
                        backgroundColor: AppColors.surfaceContainerHigh,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mengunduh APK... ${(progress * 100).toStringAsFixed(0)}%',
                      style: AppTypography.labelXs.copyWith(
                        color: AppColors.primaryStrong,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isDownloading)
                        TextButton(
                          onPressed: () {
                            context.read<UpdateCubit>().dismissPrompt(release);
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Nanti'),
                        ),
                      if (!isDownloading && onOpenSettings != null) ...[
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () {
                            context.read<UpdateCubit>().dismissPrompt(release);
                            Navigator.of(context).pop();
                            onOpenSettings!();
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLow,
                            foregroundColor: AppColors.onSurface,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Pengaturan'),
                        ),
                      ],
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: isDownloading
                              ? null
                              : () => context
                                  .read<UpdateCubit>()
                                  .downloadAndInstall(release),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.download_rounded, size: 19),
                          label: Text(
                            isDownloading
                                ? 'Mengunduh...'
                                : 'Update Sekarang',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
