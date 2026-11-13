import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/pos_repository.dart';

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
  final PosRepository repository;

  CheckoutCubit({required this.repository}) : super(CheckoutInitial());

  Future<void> processPayment({
    required List<CartItemModel> items,
    required String orderType, // 'dine_in' | 'takeaway' | 'delivery'
    required String paymentMethod, // 'cash' | 'qris' | 'debit' | 'bank_transfer'
    required int discountIdr,
    required int taxIdr,
    required int amountReceivedIdr,
    String? customerName,
  }) async {
    emit(CheckoutProcessing());
    try {
      final tx = await repository.createSale(
        items: items,
        orderType: orderType,
        paymentMethod: paymentMethod,
        discountIdr: discountIdr,
        taxIdr: taxIdr,
        amountReceivedIdr: amountReceivedIdr,
        customerName: customerName,
      );
      emit(CheckoutSuccess(tx));
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
