import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';

class CartState {
  final List<CartItemModel> items;
  final String customerName;
  final String tableName;
  final String? promoCode;
  final double discountRate;

  CartState({
    required this.items,
    this.customerName = 'Walk-in Customer',
    this.tableName = 'Table 01',
    this.promoCode,
    this.discountRate = 0.0
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get subTotal => items.fold(0, (sum, item) => sum + item.subtotal);

  double get discountAmount => subTotal * discountRate;

  double get taxAmount => (subTotal - discountAmount) * 0.10;

  double get grandTotal => (subTotal - discountAmount) + taxAmount;

  CartState copyWith({
    List<CartItemModel>? items,
    String? customerName,
    String? tableName,
    String? promoCode,
    double? discountRate,
  }) {
    return CartState(
      items: items ?? this.items,
      customerName: customerName ?? this.customerName,
      tableName: tableName ?? this.tableName,
      promoCode: promoCode ?? this.promoCode,
      discountRate: discountRate ?? this.discountRate
    );
  }
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(CartState(items: []));

  void addToCart(ProductModel product) {
    final currentItems = List<CartItemModel>.from(state.items);
    final index = currentItems.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      final existingItem = currentItems[index];

      if (existingItem.quantity < product.stock) {
        currentItems[index] = existingItem.copyWith(quantity: existingItem.quantity + 1);
      }
    } else {
      if (product.stock > 0) {
        currentItems.add(CartItemModel(product: product, quantity: 1));
      }
    }
    emit(state.copyWith(items: currentItems));
  }

  void removeFromCart(String productId) {
    final currentItems = List<CartItemModel>.from(state.items);
    final index = currentItems.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      final existingItem = currentItems[index];
      if (existingItem.quantity > 1) {
        currentItems[index] = existingItem.copyWith(quantity: existingItem.quantity - 1);
      } else {
        currentItems.removeAt(index);
      }
    }
    emit(state.copyWith(items: currentItems));
  }

  void updateCustomerInfo(String name, String table) {
    emit(state.copyWith(customerName: name, tableName: table));
  }

  bool applyPromoCode(String code) {
    if (code.trim().toUpperCase() == 'TERATUR10') {
      emit(state.copyWith(promoCode: 'TERATUR10', discountRate: 0.10));
      return true;
    }
    return false;
  }

  void clearCart() {
    emit(CartState(items: []));
  }
}
