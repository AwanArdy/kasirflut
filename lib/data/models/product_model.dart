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
  final String name;
  final String categoryId;
  final String categoryName;
  final double price;
  final int stock;
  final int lowStockThreshold;
  final String? imageUrl;

  ProductModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    required this.stock,
    required this.lowStockThreshold,
    this.imageUrl
  });

  bool get isLowStock => stock <= lowStockThreshold;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String, 
      name: json['name'] as String, 
      categoryId: json['categoryId'] as String? ?? '', 
      categoryName: json['categoryName']?['name'] as String? ?? '', 
      price: (json['price'] as num).toDouble(), 
      stock: json['stock'] as int? ?? 0, 
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 5, 
      imageUrl: json['image'] as String?,
    );
  }
}
