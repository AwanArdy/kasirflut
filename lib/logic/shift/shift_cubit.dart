import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/shift_model.dart';

abstract class ShiftState {}
class ShiftClosed extends ShiftState {}
class ShiftLoading extends ShiftState {}

class ShiftActive extends ShiftState {
  final ShiftModel session;
  ShiftActive(this.session);
}

class ShiftSummaryLoaded extends ShiftState {
  final ShiftSummaryModel summary;
  ShiftSummaryLoaded(this.summary);
}

class ShiftError extends ShiftState {
  final String message;
  ShiftError(this.message);
}

class ShiftCubit extends Cubit<ShiftState> {
  final ApiClient apiClient;

  ShiftCubit({required this.apiClient}) : super(ShiftClosed());

  Future<void> openShift({
    required String employeeId,
    required String pin,
    required double openingCash,
  }) async {
    emit(ShiftLoading());
    try {
      final res = await apiClient.post(
        '/shifts/open',
        data: {
          'employeeId': employeeId,
          'pin': pin,
          'openingCash': openingCash,
        },
      );
      final shift = ShiftModel.fromJson(res['data']);
      emit(ShiftActive(shift));
    } on ApiException catch (e) {
      emit(ShiftError(e.message));
    } catch (_) {
      emit(ShiftError('Gagal membuka sesi kasir.'));
    }
  }

  Future<void> closeShift({
    required String employeeId,
    required String pin,
    double? countedCash,
  }) async {
    emit(ShiftLoading());
    try {
      final res = await apiClient.post(
        '/shifts/close',
        data: {
          'employeeId': employeeId,
          'pin': pin,
          if (countedCash != null) 'countedCash': countedCash,
        },
      );
      final summary = ShiftSummaryModel.fromJson(res['data']);
      emit(ShiftSummaryLoaded(summary));
    } on ApiException catch (e) {
      emit(ShiftError(e.message));
    } catch (_) {
      emit(ShiftError('Gagal menutup sesi kasir.'));
    }
  }
}
