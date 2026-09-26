import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/transaction_model.dart';

abstract class CheckoutState {}
class CheckoutInitial extends CheckoutState {}
class CheckoutProcessing extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final TransactionModel transaction;
  CheckoutSuccess(this.transaction);
}

class CheckoutError extends CheckoutState {
  final String message;
  CheckoutError(this.message);
}

class CheckoutCubit extends Cubit<CheckoutState> {
  final ApiClient apiClient;

  CheckoutCubit({required this.apiClient}) : super(CheckoutInitial());

  Future<void> processPayment({
    required List<CartItemModel> items,
    required String customerName,
    required String tableName,
    required double discount,
    required String paymentMethod, // 'CASH' | 'QRIS' | 'TRANSFER' | 'CARD'[cite: 2]
    required double amountReceived,
  }) async {
    emit(CheckoutProcessing());
    
    // Step 1: Generate Idempotency Key unik sebelum API call[cite: 2]
    final idempotencyKey = const Uuid().v4();

    try {
      // Step 2: Buat draf Transaksi (POST /transactions)[cite: 2]
      final createRes = await apiClient.post(
        '/transactions',
        idempotencyKey: idempotencyKey,
        data: {
          'items': items.map((e) => e.toTransactionPayload()).toList(),
          'customerName': customerName,
          'tableName': tableName,
          'discount': discount,
        },
      );

      final transactionId = createRes['data']['id'] as String;

      // Step 3: Bayar Transaksi (POST /transactions/:id/pay)[cite: 2]
      final payRes = await apiClient.post(
        '/transactions/$transactionId/pay',
        data: {
          'method': paymentMethod,
          'amountReceived': amountReceived,
        },
      );

      final completedTransaction = TransactionModel.fromJson(payRes['data']);
      emit(CheckoutSuccess(completedTransaction));
    } on ApiException catch (e) {
      emit(CheckoutError(e.message));
    } catch (_) {
      emit(CheckoutError('Terjadi kesalahan saat memproses pembayaran.'));
    }
  }

  void reset() {
    emit(CheckoutInitial());
  }
}
