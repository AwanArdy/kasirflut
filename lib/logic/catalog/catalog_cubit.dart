import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/product_model.dart';

abstract class CatalogState {}
class CatalogInitial extends CatalogState {}
class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<ProductModel> allProducts;
  final List<CategoryModel> categories;
  final String selectedCategoryId;
  final String searchQuery;

  CatalogLoaded({
    required this.allProducts,
    required this.categories,
    this.selectedCategoryId = 'ALL',
    this.searchQuery = '',
  });

  List<ProductModel> get filteredProducts {
    return allProducts.where((product) {
      final matchesCategory = selectedCategoryId == 'ALL' || product.categoryId == selectedCategoryId;
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CatalogLoaded copyWith({
    List<ProductModel>? allProducts,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return CatalogLoaded(
      allProducts: allProducts ?? this.allProducts, 
      categories: categories ?? this.categories, 
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId, 
      searchQuery: searchQuery ?? this.searchQuery
    );
  }
}

class CatalogError extends CatalogState {
  final String message;
  CatalogError(this.message);
}

class CatalogCubit extends Cubit<CatalogState> {
  final ApiClient apiClient;

  CatalogCubit({required this.apiClient}) : super(CatalogInitial());

  Future<void> fetchCatalog() async {
    emit(CatalogLoading());
    try {
      final productRes = await apiClient.get('/products');
      final categoriesRes = await apiClient.get('/categories');

      final products = (productRes['data'] as List)
        .map((item) => ProductModel.fromJson(item))
        .toList();

      final categories = (categoriesRes['data'] as List)
        .map((item) => CategoryModel.fromJson(item))
        .toList();

      emit(CatalogLoaded(allProducts: products, categories: categories));
    } on ApiException catch (e) {
      emit(CatalogError(e.message));
    } catch (_) {
      emit(CatalogError('Gagal memuat katalog menu'));
    }
  }

  void filterByCategory(String categoryId) {
    if (state is CatalogLoaded) {
      final currentState = state as CatalogLoaded;
      emit(currentState.copyWith(selectedCategoryId: categoryId));
    }
  }

  void searchMenu(String query) {
    if (state is CatalogLoaded) {
      final currentState = state as CatalogLoaded;
      emit(currentState.copyWith(searchQuery: query));
    }
  }
}
