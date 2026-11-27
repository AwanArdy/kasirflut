import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
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

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Update Tersedia (v${release.version})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260, maxWidth: 400),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Catatan Pembaruan:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Text(
                      release.notes.isNotEmpty
                          ? release.notes
                          : 'Perbaikan performa dan stabilitas aplikasi.',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Jika outlet sedang ramai, kamu bisa menutup pesan ini dan melakukan update nanti lewat menu Setting.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (isDownloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress > 0 ? progress : null),
                    const SizedBox(height: 6),
                    Text(
                      'Mengunduh APK... ${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (!isDownloading)
              TextButton(
                onPressed: () {
                  context.read<UpdateCubit>().dismissPrompt(release);
                  Navigator.of(context).pop();
                },
                child: const Text('Nanti'),
              ),
            if (!isDownloading && onOpenSettings != null)
              OutlinedButton(
                onPressed: () {
                  context.read<UpdateCubit>().dismissPrompt(release);
                  Navigator.of(context).pop();
                  onOpenSettings!();
                },
                child: const Text('Ke Setting'),
              ),
            FilledButton(
              onPressed: isDownloading
                  ? null
                  : () => context.read<UpdateCubit>().downloadAndInstall(release),
              child: Text(isDownloading ? 'Mengunduh...' : 'Update Sekarang'),
            ),
          ],
        );
      },
    );
  }
 }
