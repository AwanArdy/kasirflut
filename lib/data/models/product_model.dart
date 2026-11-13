class CategoryModel {
  final String id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class ProductModel {
  final String id;
  final String sku;
  final String name;
  final String category;
  final int sellingPriceIdr;
  final String kind; // 'made_to_order' | 'finished_good' | 'pre_order'
  final bool isActive;
  final String? imageUrl;

  ProductModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.sellingPriceIdr,
    this.kind = 'made_to_order',
    this.isActive = true,
    this.imageUrl,
  });

  double get price => sellingPriceIdr.toDouble();
  String get categoryId => category;
  String get categoryName => category;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Lainnya',
      sellingPriceIdr: (json['sellingPriceIdr'] as num?)?.toInt() ?? 0,
      kind: json['kind'] as String? ?? 'made_to_order',
      isActive: json['isActive'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      sku: map['sku'] as String? ?? '',
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Lainnya',
      sellingPriceIdr: (map['selling_price_idr'] as num).toInt(),
      kind: map['kind'] as String? ?? 'made_to_order',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'category': category,
      'selling_price_idr': sellingPriceIdr,
      'kind': kind,
      'is_active': isActive ? 1 : 0,
      'image_url': imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
