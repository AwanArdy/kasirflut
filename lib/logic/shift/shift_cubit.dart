import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/shift_model.dart';
import '../../data/repositories/pos_repository.dart';

abstract class ShiftState {}

class ShiftClosed extends ShiftState {}

class ShiftLoading extends ShiftState {}

class ShiftActive extends ShiftState {
  final ShiftModel session;
  ShiftActive(this.session);
}

class ShiftClosedSummary extends ShiftState {
  final ShiftModel closedShift;
  ShiftClosedSummary(this.closedShift);
}

class ShiftError extends ShiftState {
  final String message;
  ShiftError(this.message);
}

class ShiftCubit extends Cubit<ShiftState> {
  final PosRepository repository;

  ShiftCubit({required this.repository}) : super(ShiftClosed());

  Future<void> loadActiveShift({bool silent = false}) async {
    final hadActiveShift = state is ShiftActive;
    if (!silent && !hadActiveShift) {
      emit(ShiftLoading());
    }

    try {
      final active = await repository.getActiveShift();
      if (active != null && active.isOpen) {
        emit(ShiftActive(active));
      } else if (!silent) {
        emit(ShiftClosed());
      }
    } on ApiException catch (e) {
      if (!silent && !hadActiveShift) {
        emit(ShiftError(e.message));
      }
    } catch (_) {
      if (!silent && !hadActiveShift) {
        emit(ShiftClosed());
      }
    }
  }

  Future<void> openShift({
    required int startingCashIdr,
    required String shiftName,
    String? notes,
  }) async {
    emit(ShiftLoading());
    try {
      final shift = await repository.openShift(
        startingCashIdr: startingCashIdr,
        shiftName: shiftName,
        notes: notes,
      );
      emit(ShiftActive(shift));
    } on ApiException catch (e) {
      emit(ShiftError(e.message));
    } catch (_) {
      emit(ShiftError('Gagal membuka sesi kasir.'));
    }
  }

  Future<void> closeShift({
    required int actualPhysicalCashIdr,
    String? notes,
  }) async {
    emit(ShiftLoading());
    try {
      final closed = await repository.closeShift(
        actualPhysicalCashIdr: actualPhysicalCashIdr,
        notes: notes,
      );
      emit(ShiftClosedSummary(closed));
    } on ApiException catch (e) {
      emit(ShiftError(e.message));
    } catch (_) {
      emit(ShiftError('Gagal menutup sesi kasir.'));
    }
  }
}
