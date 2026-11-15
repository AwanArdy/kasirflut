import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/pos_repository.dart';

abstract class CatalogState {}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<ProductModel> allProducts;
  final List<CategoryModel> categories;
  final String selectedCategoryId;
  final String searchQuery;
  final bool isOfflineCache;

  CatalogLoaded({
    required this.allProducts,
    required this.categories,
    this.selectedCategoryId = 'ALL',
    this.searchQuery = '',
    this.isOfflineCache = false,
  });

  List<ProductModel> get filteredProducts {
    return allProducts.where((product) {
      final matchesCategory = selectedCategoryId == 'ALL' ||
          product.category == selectedCategoryId;
      final q = searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          product.name.toLowerCase().contains(q) ||
          product.sku.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  CatalogLoaded copyWith({
    List<ProductModel>? allProducts,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
    String? searchQuery,
    bool? isOfflineCache,
  }) {
    return CatalogLoaded(
      allProducts: allProducts ?? this.allProducts,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      isOfflineCache: isOfflineCache ?? this.isOfflineCache,
    );
  }
}

class CatalogError extends CatalogState {
  final String message;
  CatalogError(this.message);
}

class CatalogCubit extends Cubit<CatalogState> {
  final PosRepository repository;

  CatalogCubit({required this.repository}) : super(CatalogInitial());

  Future<void> fetchCatalog() async {
    emit(CatalogLoading());
    try {
      final result = await repository.fetchMenu();
      final categoryNames = result.products
          .map((p) => p.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final categories = categoryNames
          .map((name) => CategoryModel(id: name, name: name))
          .toList();

      emit(
        CatalogLoaded(
          allProducts: result.products,
          categories: categories,
          isOfflineCache: result.fromOfflineCache,
        ),
      );
    } on ApiException catch (e) {
      emit(CatalogError(e.message));
    } catch (e, stackTrace) {
      print('ERROR FETCH CATALOG: $e');
      print(stackTrace);
      emit(CatalogError('Gagal memuat katalog menu: $e'));
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
