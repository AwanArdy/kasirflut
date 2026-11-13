import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';

class CartState {
  final List<CartItemModel> items;
  final String customerName;
  final String orderType; // 'dine_in' | 'takeaway' | 'delivery'
  final String? promoCode;
  final double discountRate;
  final bool includeTax;

  CartState({
    required this.items,
    this.customerName = 'Walk-in Customer',
    this.orderType = 'dine_in',
    this.promoCode,
    this.discountRate = 0.0,
    this.includeTax = true,
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  int get subTotalIdr => items.fold(0, (sum, item) => sum + item.subtotalIdr);
  double get subTotal => subTotalIdr.toDouble();

  int get discountAmountIdr => (subTotalIdr * discountRate).round();
  double get discountAmount => discountAmountIdr.toDouble();

  int get taxAmountIdr =>
      includeTax ? ((subTotalIdr - discountAmountIdr) * 0.10).round() : 0;
  double get taxAmount => taxAmountIdr.toDouble();

  int get grandTotalIdr => (subTotalIdr - discountAmountIdr) + taxAmountIdr;
  double get grandTotal => grandTotalIdr.toDouble();

  String get orderTypeLabel {
    switch (orderType) {
      case 'takeaway':
        return 'Takeaway';
      case 'delivery':
        return 'Delivery';
      default:
        return 'Dine In';
    }
  }

  CartState copyWith({
    List<CartItemModel>? items,
    String? customerName,
    String? orderType,
    String? promoCode,
    double? discountRate,
    bool? includeTax,
  }) {
    return CartState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      orderType: orderType ?? this.orderType,
      promoCode: promoCode ?? this.promoCode,
      discountRate: discountRate ?? this.discountRate,
      includeTax: includeTax ?? this.includeTax,
    );
  }
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState(items: []));

  void addToCart(ProductModel product) {
    final currentItems = List<CartItemModel>.from(state.items);
    final index =
        currentItems.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      final existingItem = currentItems[index];
      currentItems[index] =
          existingItem.copyWith(quantity: existingItem.quantity + 1);
    } else {
      currentItems.add(CartItemModel(product: product, quantity: 1));
    }
    emit(state.copyWith(items: currentItems));
  }

  void removeFromCart(String productId) {
    final currentItems = List<CartItemModel>.from(state.items);
    final index =
        currentItems.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      final existingItem = currentItems[index];
      if (existingItem.quantity > 1) {
        currentItems[index] =
            existingItem.copyWith(quantity: existingItem.quantity - 1);
      } else {
        currentItems.removeAt(index);
      }
    }
    emit(state.copyWith(items: currentItems));
  }

  void updateOrderInfo({String? customerName, String? orderType}) {
    emit(state.copyWith(
      customerName: customerName,
      orderType: orderType,
    ));
  }

  void toggleTax(bool includeTax) {
    emit(state.copyWith(includeTax: includeTax));
  }

  bool applyPromoCode(String code) {
    if (code.trim().toUpperCase() == 'TERATUR10') {
      emit(state.copyWith(promoCode: 'TERATUR10', discountRate: 0.10));
      return true;
    }
    return false;
  }

  void clearPromoCode() {
    emit(CartState(
      items: state.items,
      customerName: state.customerName,
      orderType: state.orderType,
      includeTax: state.includeTax,
    ));
  }

  void clearCart() {
    emit(CartState(items: []));
  }
}
