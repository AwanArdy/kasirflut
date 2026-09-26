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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Produk (Aspect Ratio 1:1)
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.surfaceDim),
                          errorWidget: (context, url, error) => const Icon(Icons.fastfood, size: 40, color: AppColors.outline),
                        )
                      : Container(
                          color: AppColors.surfaceContainerLow,
                          child: const Icon(Icons.fastfood, size: 40, color: AppColors.outline),
                        ),
                ),
              ),
              // Low Stock Warning Badge
              if (product.isLowStock)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Stok ${product.stock}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.warningText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Detail Teks Produk
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(product.categoryName, style: AppTypography.bodySm),
                const SizedBox(height: 8),
                Text(
                  formatRupiah(product.price),
                  style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
                ),
                const SizedBox(height: 12),

                // Tombol Aksi Tambah / Pengatur Qty
                if (cartQty == 0)
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: product.stock > 0 ? onAdd : null,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      Text(
                        '$cartQty',
                        style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: cartQty < product.stock ? onAdd : null,
                        icon: const Icon(Icons.add, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
