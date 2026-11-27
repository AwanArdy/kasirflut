import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/repositories/update_repository.dart';
import '../../logic/update/update_cubit.dart';

Future<void> showSettingsModal(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const SettingsModal(),
  );
}

class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final updateRepo = context.read<UpdateRepository>();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengaturan Aplikasi',
                          style: AppTypography.headlineSm.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        FutureBuilder<String>(
                          future: updateRepo.getCurrentVersion(),
                          builder: (context, snapshot) {
                            final ver = snapshot.data ?? '-';
                            return Text(
                              'TeraturPOS • Versi terpasang v$ver',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Bagian Pembaruan Aplikasi
              Text(
                'Pembaruan Aplikasi',
                style: AppTypography.labelSm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              BlocBuilder<UpdateCubit, UpdateState>(
                builder: (context, state) {
                  if (state is UpdateChecking) {
                    return _buildInfoBox(
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Mengecek pembaruan dari server...'),
                        ],
                      ),
                    );
                  }

                  if (state is UpdateDownloading) {
                    final pct = (state.progress * 100).toStringAsFixed(0);
                    return _buildInfoBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mengunduh v${state.release.version} ($pct%)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: state.progress > 0 ? state.progress : null,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Jangan tutup aplikasi sampai proses unduhan selesai.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is UpdateAvailable) {
                    return _buildInfoBox(
                      bgColor: AppColors.primaryContainer.withValues(alpha: 0.45),
                      borderColor: AppColors.primary.withValues(alpha: 0.4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.new_releases_rounded,
                                size: 18,
                                color: AppColors.primaryStrong,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Versi Baru Tersedia: v${state.release.version}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryStrong,
                                ),
                              ),
                            ],
                          ),
                          if (state.release.notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 120),
                              child: SingleChildScrollView(
                                child: Text(
                                  state.release.notes,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => context
                                  .read<UpdateCubit>()
                                  .downloadAndInstall(state.release),
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: const Text('Unduh & Instal Update'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is UpdateUpToDate) {
                    return _buildInfoBox(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primaryStrong,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Aplikasi sudah menggunakan versi terbaru (v${state.currentVersion}).',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is UpdateError) {
                    return _buildInfoBox(
                      bgColor: AppColors.dangerBg,
                      borderColor: AppColors.error.withValues(alpha: 0.4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.errorStrong,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.errorStrong,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return _buildInfoBox(
                    child: const Text(
                      'Tekan tombol di bawah untuk mengecek versi terbaru aplikasi.',
                      style: TextStyle(fontSize: 13),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Tombol Cek Pembaruan Manual
              BlocBuilder<UpdateCubit, UpdateState>(
                builder: (context, state) {
                  final isBusy =
                      state is UpdateChecking || state is UpdateDownloading;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: isBusy
                            ? null
                            : () =>
                                context.read<UpdateCubit>().checkManually(),
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text('Cek Pembaruan'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required Widget child,
    Color bgColor = AppColors.surfaceContainerLow,
    Color borderColor = AppColors.outlineVariant,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}
