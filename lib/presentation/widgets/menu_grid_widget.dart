import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/catalog/catalog_cubit.dart';
import 'product_card_widget.dart';

class MenuGridWidget extends StatelessWidget {
  const MenuGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        if (state is CatalogLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (state is CatalogError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.message,
                    style:
                        AppTypography.bodyLg.copyWith(color: AppColors.error)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<CatalogCubit>().fetchCatalog(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (state is CatalogLoaded) {
          final products = state.filteredProducts;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Search Input
                Row(
                  children: [
                    Text('List Menu', style: AppTypography.headlineMd),
                    const Spacer(),
                    SizedBox(
                      width: 280,
                      height: 44,
                      child: TextField(
                        onChanged: (val) => context.read<CatalogCubit>().searchMenu(val),
                        decoration: InputDecoration(
                          hintText: 'Cari menu...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (state.isOfflineCache)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off,
                            size: 16, color: AppColors.warningText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mode Offline: Menampilkan menu dari cache SQLite lokal.',
                            style: AppTypography.labelSm
                                .copyWith(color: AppColors.warningText),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Horizontal Category Pills
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final catId = isAll ? 'ALL' : state.categories[index - 1].id;
                      final catName = isAll ? 'All Menu' : state.categories[index - 1].name;
                      final isSelected = state.selectedCategoryId == catId;

                      return GestureDetector(
                        onTap: () => context.read<CatalogCubit>().filterByCategory(catId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: isSelected ? null : Border.all(color: AppColors.outlineVariant),
                          ),
                          child: Text(
                            catName,
                            style: AppTypography.labelMd.copyWith(
                              color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Grid Catalog Products
                Expanded(
                  child: BlocBuilder<CartCubit, CartState>(
                    builder: (context, cartState) {
                      return GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // Adaptif 3-4 kolom
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final item = products[index];
                          final cartItemIndex = cartState.items.indexWhere((c) => c.product.id == item.id);
                          final qty = cartItemIndex >= 0 ? cartState.items[cartItemIndex].quantity : 0;

                          return ProductCardWidget(
                            product: item,
                            cartQty: qty,
                            onAdd: () => context.read<CartCubit>().addToCart(item),
                            onRemove: () => context.read<CartCubit>().removeFromCart(item.id),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
