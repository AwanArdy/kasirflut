import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/product_model.dart';
import '../../utils/currency_formatter.dart';

class ProductCardWidget extends StatelessWidget {
  final ProductModel product;
  final int cartQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.cartQty,
    required this.onAdd,
    required this.onRemove,
  });

  IconData _resolveCategoryIcon() {
    final cat = '${product.category} ${product.categoryName}'.toLowerCase();
    if (cat.contains('pastry') ||
        cat.contains('roti') ||
        cat.contains('cake') ||
        cat.contains('bakery')) {
      return Icons.bakery_dining_rounded;
    }
    if (cat.contains('makan') ||
        cat.contains('food') ||
        cat.contains('snack') ||
        cat.contains('berat')) {
      return Icons.lunch_dining_rounded;
    }
    if (cat.contains('tea') ||
        cat.contains('teh') ||
        cat.contains('non') ||
        cat.contains('matcha') ||
        cat.contains('juice')) {
      return Icons.emoji_food_beverage_rounded;
    }
    return Icons.local_cafe_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isInCart = cartQty > 0;
    final categoryIcon = _resolveCategoryIcon();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isInCart
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.45), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isInCart
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: isInCart ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Icon Canvas + Category & Qty Badges
              Expanded(
                flex: 10,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isInCart
                        ? AppColors.surfaceContainer
                        : AppColors.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isInCart
                                ? AppColors.primaryContainer
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.onSurface.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            categoryIcon,
                            size: 30,
                            color: AppColors.primaryStrong,
                          ),
                        ),
                      ),

                      // Category Badge (Top-Left)
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.onSurface.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            product.categoryName,
                            style: AppTypography.labelXs.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ),

                      // Circular Quantity Badge (Top-Right)
                      if (isInCart)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '$cartQty',
                              style: AppTypography.labelXs.copyWith(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Product Info & Bottom Stepper
              Expanded(
                flex: 11,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatRupiah(product.price),
                        style: AppTypography.headlineSm.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryStrong,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!isInCart)
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Tambah',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimaryContainer,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 38,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Material(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(9),
                                child: InkWell(
                                  onTap: onRemove,
                                  borderRadius: BorderRadius.circular(9),
                                  child: const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Icon(
                                      Icons.remove_rounded,
                                      size: 18,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                '$cartQty',
                                style: AppTypography.labelMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Material(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(9),
                                child: InkWell(
                                  onTap: onAdd,
                                  borderRadius: BorderRadius.circular(9),
                                  child: const SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
