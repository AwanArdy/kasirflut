import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/release_info_model.dart';
import '../../data/repositories/update_repository.dart';

sealed class UpdateState {}

class UpdateInitial extends UpdateState {}

class UpdateChecking extends UpdateState {}

class UpdateAvailable extends UpdateState {
  final ReleaseInfo release;
  final bool showDialogPrompt;

  UpdateAvailable({
    required this.release,
    required this.showDialogPrompt,
  });
}

class UpdateUpToDate extends UpdateState {
  final String currentVersion;
  UpdateUpToDate(this.currentVersion);
}

class UpdateDownloading extends UpdateState {
  final ReleaseInfo release;
  final double progress;

  UpdateDownloading({
    required this.release,
    required this.progress,
  });
}

class UpdateError extends UpdateState {
  final String message;
  UpdateError(this.message);
}

class UpdateCubit extends Cubit<UpdateState> {
  final UpdateRepository _repository;
  bool _hasCheckedOnStart = false;

  UpdateCubit({required UpdateRepository repository})
    : _repository = repository,
      super(UpdateInitial());

  Future<void> checkOnAppStart() async {
    if (_hasCheckedOnStart) return;
    _hasCheckedOnStart = true;

    try {
      final release = await _repository.checkForUpdate(ignoreDismissed: false);
      if (release != null) {
        emit(UpdateAvailable(release: release, showDialogPrompt: true));
      }
    } catch (_) {

    }
  }

  Future<void> checkManually() async {
    emit(UpdateChecking());
    try {
      final release = await _repository.checkForUpdate(ignoreDismissed: true);
      if (release != null) {
        emit(UpdateAvailable(release: release, showDialogPrompt: false));
      } else {
        final current = await _repository.getCurrentVersion();
        emit(UpdateUpToDate(current));
      }
    } catch (e) {
      emit(UpdateError('Gagal mengecek pembaruan. Periksa koneksi internet'));
    }
  }

  Future<void> dismissPrompt(ReleaseInfo release) async {
    await _repository.dismissVersion(release.version);
    emit(UpdateAvailable(release: release, showDialogPrompt: false));
  }

  Future<void> downloadAndInstall(ReleaseInfo release) async {
    emit(UpdateDownloading(release: release, progress: 0));
    try {
      await _repository.downloadAndInstallApk(
        release,
        onProgress: (progress) {
          emit(UpdateDownloading(release: release, progress: progress));
        },
      );
      emit(UpdateAvailable(release: release, showDialogPrompt: false));
    } catch (e) {
      emit(UpdateError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
