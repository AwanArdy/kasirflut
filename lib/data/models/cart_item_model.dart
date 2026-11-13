import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;
  final String? note;

  CartItemModel({
    required this.product,
    required this.quantity,
    this.note,
  });

  int get subtotalIdr => product.sellingPriceIdr * quantity;
  double get subtotal => subtotalIdr.toDouble();

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    String? note,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  /// Payload item sesuai kontrak backend `POST /pos/sales` (`posSaleSchema`)
  Map<String, dynamic> toPosSaleItemPayload() {
    return {
      'productId': product.id,
      'qty': quantity,
      'unitPriceIdr': product.sellingPriceIdr,
    };
  }
}
