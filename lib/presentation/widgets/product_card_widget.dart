import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    final isSnack = product.category.toLowerCase().contains('pastry') ||
        product.category.toLowerCase().contains('snack');
    final isInCart = cartQty > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInCart ? AppColors.primary : AppColors.outlineVariant,
          width: isInCart ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isInCart
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: isInCart ? 14 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image + Badges
              Expanded(
                flex: 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: product.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceContainerLow,
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surfaceContainerLow,
                                child: Center(
                                  child: Icon(
                                    isSnack
                                        ? Icons.bakery_dining_rounded
                                        : Icons.local_cafe_rounded,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceContainerLow,
                              child: Center(
                                child: Icon(
                                  isSnack
                                      ? Icons.bakery_dining_rounded
                                      : Icons.local_cafe_rounded,
                                  size: 42,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    ),
                    // Category pill
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
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          product.categoryName,
                          style: AppTypography.labelSm.copyWith(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Cart Quantity Badge
                    if (isInCart)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.onSurface
                                    .withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${cartQty}x',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Info & Action
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatRupiah(product.price),
                        style: AppTypography.headlineSm.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryStrong,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!isInCart)
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              'Tambah',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimaryContainer,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: onRemove,
                                borderRadius: BorderRadius.circular(9),
                                child: const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 18,
                                    color: AppColors.primaryStrong,
                                  ),
                                ),
                              ),
                              Text(
                                '$cartQty',
                                style: AppTypography.bodyMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              InkWell(
                                onTap: onAdd,
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                    color: AppColors.onPrimary,
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
