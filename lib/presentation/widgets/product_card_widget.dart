import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.25,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: AppColors.surfaceDim),
                      errorWidget: (context, url, error) => Icon(
                        isSnack ? Icons.bakery_dining : Icons.local_cafe,
                        size: 40,
                        color: AppColors.outline,
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceContainerLow,
                      child: Center(
                        child: Icon(
                          isSnack ? Icons.bakery_dining : Icons.local_cafe,
                          size: 42,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(product.categoryName, style: AppTypography.bodySm),
                const SizedBox(height: 8),
                Text(
                  formatRupiah(product.price),
                  style: AppTypography.headlineSm
                      .copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 10),
                if (cartQty == 0)
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.remove, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      Text(
                        '$cartQty',
                        style: AppTypography.bodyMd
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
