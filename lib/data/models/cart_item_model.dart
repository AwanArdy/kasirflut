import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;
  final String? note;

  CartItemModel({
    required this.product,
    required this.quantity,
    this.note
  });

  double get subtotal => product.price * quantity;

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    String? note,
  }) {
    return CartItemModel(
      product: product ?? this.product, 
      quantity: quantity ?? this.quantity, 
      note: note ?? this.note
    );
  }

  Map<String, dynamic> toTransactionPayload() {
    return {
      'productId': product.id,
      'quantity': quantity,
      'price': product.price,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}
