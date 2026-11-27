import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/catalog/catalog_cubit.dart';
import 'offline_queue_modal.dart';
import 'product_card_widget.dart';

class MenuGridWidget extends StatefulWidget {
  const MenuGridWidget({super.key});

  @override
  State<MenuGridWidget> createState() => _MenuGridWidgetState();
}

class _MenuGridWidgetState extends State<MenuGridWidget> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, state) {
        if (state is CatalogLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is CatalogError) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.dangerBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.errorStrong,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    state.message,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.errorStrong,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<CatalogCubit>().fetchCatalog(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is CatalogLoaded) {
          final products = state.filteredProducts;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Quick Search
                Row(
                  children: [
                    Flexible(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          Text(
                            'Katalog Menu',
                            style: AppTypography.headlineMd.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${products.length} Menu Tersedia',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 310,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.onSurface.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            context.read<CatalogCubit>().searchMenu(val),
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari nama produk atau SKU...',
                          hintStyle: AppTypography.bodySm.copyWith(
                            color: AppColors.outline,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.outline,
                            size: 20,
                          ),
                          suffixIcon: state.searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.outline,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<CatalogCubit>().searchMenu('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Offline Banner with Quick Queue Action
                if (state.isOfflineCache)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 19,
                          color: AppColors.warningText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mode Offline Aktif — Menampilkan katalog lokal SQLite & siap sinkron otomatis.',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.warningText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => showOfflineQueueModal(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.onSurface
                                      .withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              'Cek Antrean',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.warningText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Horizontal Category Filter Pills
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final catId =
                          isAll ? 'ALL' : state.categories[index - 1].id;
                      final catName = isAll
                          ? 'Semua Menu'
                          : state.categories[index - 1].name;
                      final isSelected = state.selectedCategoryId == catId;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context
                              .read<CatalogCubit>()
                              .filterByCategory(catId),
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondaryFixedDim
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primary
                                          .withValues(alpha: 0.22)
                                      : AppColors.onSurface
                                          .withValues(alpha: 0.04),
                                  blurRadius: isSelected ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  catName,
                                  style: AppTypography.labelMd.copyWith(
                                    fontSize: 13,
                                    letterSpacing: 0.1,
                                    color: AppColors.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (isAll) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.surface
                                              .withValues(alpha: 0.55)
                                          : AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${products.length}',
                                      style: AppTypography.labelXs.copyWith(
                                        color: isSelected
                                            ? AppColors.onSurface
                                            : AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Responsive Grid Catalog Products
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.search_off_rounded,
                                  size: 32,
                                  color: AppColors.outline,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Menu tidak ditemukan',
                                style: AppTypography.headlineSm,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coba ubah kata kunci atau pilih kategori lain.',
                                style: AppTypography.bodySm,
                              ),
                              if (state.searchQuery.isNotEmpty ||
                                  state.selectedCategoryId != 'ALL') ...[
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    context.read<CatalogCubit>().searchMenu('');
                                    context
                                        .read<CatalogCubit>()
                                        .filterByCategory('ALL');
                                  },
                                  icon: const Icon(
                                    Icons.restart_alt_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Reset Filter'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final crossAxisCount = width >= 880
                                ? 4
                                : width >= 540
                                    ? 3
                                    : 2;

                            return BlocBuilder<CartCubit, CartState>(
                              builder: (context, cartState) {
                                return GridView.builder(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.86,
                                    crossAxisSpacing: 14,
                                    mainAxisSpacing: 14,
                                  ),
                                  itemCount: products.length,
                                  itemBuilder: (context, index) {
                                    final item = products[index];
                                    final cartItemIndex = cartState.items
                                        .indexWhere(
                                            (c) => c.product.id == item.id);
                                    final qty = cartItemIndex >= 0
                                        ? cartState
                                            .items[cartItemIndex].quantity
                                        : 0;

                                    return ProductCardWidget(
                                      product: item,
                                      cartQty: qty,
                                      onAdd: () => context
                                          .read<CartCubit>()
                                          .addToCart(item),
                                      onRemove: () => context
                                          .read<CartCubit>()
                                          .removeFromCart(item.id),
                                    );
                                  },
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
