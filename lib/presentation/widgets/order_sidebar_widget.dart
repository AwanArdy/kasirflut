import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/shift/shift_cubit.dart';
import '../../utils/currency_formatter.dart';
import 'payment_modal.dart';
import 'shift_modals.dart';

class OrderSidebarWidget extends StatelessWidget {
  const OrderSidebarWidget({super.key});

  Future<void> _showCustomerNameDialog(
    BuildContext context,
    CartState state,
  ) async {
    final nameController = TextEditingController(text: state.customerName);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_restaurant_rounded,
                  color: AppColors.primaryStrong,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Pelanggan / Nomor Meja'),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nama Pelanggan atau Nomor Meja',
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  onSubmitted: (_) {
                    context.read<CartCubit>().updateOrderInfo(
                          customerName: nameController.text.trim().isEmpty
                              ? 'Walk-in Customer'
                              : nameController.text.trim(),
                          orderType: state.orderType,
                        );
                    Navigator.pop(dialogCtx);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Meja 04 / Budi',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<CartCubit>().updateOrderInfo(
                      customerName: nameController.text.trim().isEmpty
                          ? 'Walk-in Customer'
                          : nameController.text.trim(),
                      orderType: state.orderType,
                    );
                Navigator.pop(dialogCtx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidebarWidth = screenWidth >= 1200 ? 410.0 : 380.0;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Sidebar Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Order Detail',
                      style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${state.totalItemCount} Items',
                        style: AppTypography.labelXs.copyWith(
                          color: AppColors.primaryStrong,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (state.items.isNotEmpty)
                      InkWell(
                        onTap: () => context.read<CartCubit>().clearCart(),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.delete_sweep_rounded,
                                size: 16,
                                color: AppColors.errorStrong,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Clear All',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.errorStrong,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Customer & Inline Dining Mode Selector
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.table_restaurant_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.customerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMd.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () =>
                                _showCustomerNameDialog(context, state),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Inline 3-Tab Order Type Control
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _OrderTypeTab(
                                icon: Icons.restaurant_rounded,
                                label: 'Dine In',
                                selected: state.orderType == 'dine_in',
                                onTap: () =>
                                    context.read<CartCubit>().updateOrderInfo(
                                          customerName: state.customerName,
                                          orderType: 'dine_in',
                                        ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _OrderTypeTab(
                                icon: Icons.shopping_bag_rounded,
                                label: 'Takeaway',
                                selected: state.orderType == 'takeaway',
                                onTap: () =>
                                    context.read<CartCubit>().updateOrderInfo(
                                          customerName: state.customerName,
                                          orderType: 'takeaway',
                                        ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _OrderTypeTab(
                                icon: Icons.moped_rounded,
                                label: 'Delivery',
                                selected: state.orderType == 'delivery',
                                onTap: () =>
                                    context.read<CartCubit>().updateOrderInfo(
                                          customerName: state.customerName,
                                          orderType: 'delivery',
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

              // Order Ticket Stream (Scrollable)
              Expanded(
                child: state.items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 34,
                                  color: AppColors.outline,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Keranjang masih kosong',
                                style: AppTypography.headlineSm.copyWith(
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pilih menu di sebelah kiri untuk mulai mencatat pesanan.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySm,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cartItem = state.items[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartItem.product.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                AppTypography.bodySm.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${formatRupiah(cartItem.product.price)} / item',
                                            style: AppTypography.labelXs,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formatRupiah(cartItem.subtotal),
                                      style: AppTypography.labelMd.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.onSurface
                                                .withValues(alpha: 0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => context
                                                .read<CartCubit>()
                                                .removeFromCart(
                                                    cartItem.product.id),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: AppColors
                                                    .surfaceContainerLow,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.remove_rounded,
                                                size: 15,
                                                color: AppColors.onSurface,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 28,
                                            child: Text(
                                              '${cartItem.quantity}',
                                              textAlign: TextAlign.center,
                                              style: AppTypography.labelSm
                                                  .copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => context
                                                .read<CartCubit>()
                                                .addToCart(cartItem.product),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.add_rounded,
                                                size: 15,
                                                color: AppColors.onPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Payment Summary & CTAs (Locked to bottom)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: AppTypography.bodySm),
                        Text(
                          formatRupiah(state.subTotal),
                          style: AppTypography.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (state.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Diskon Promo (${state.promoCode})',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.primaryStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '-${formatRupiah(state.discountAmount)}',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.primaryStrong,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => context
                              .read<CartCubit>()
                              .toggleTax(!state.includeTax),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: state.includeTax
                                  ? AppColors.primaryContainer
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  state.includeTax
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  size: 14,
                                  color: state.includeTax
                                      ? AppColors.primaryStrong
                                      : AppColors.outline,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  state.includeTax
                                      ? 'PB1 / Pajak Resto (10%)'
                                      : 'Tanpa Pajak (0%)',
                                  style: AppTypography.labelXs.copyWith(
                                    color: state.includeTax
                                        ? AppColors.onPrimaryContainer
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          formatRupiah(state.taxAmount),
                          style: AppTypography.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Total Bayar',
                          style: AppTypography.headlineSm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          formatRupiah(state.grandTotal),
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.primaryStrong,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: state.items.isNotEmpty
                            ? () async {
                                final shiftState =
                                    context.read<ShiftCubit>().state;
                                if (shiftState is! ShiftActive) {
                                  await showOpenShiftDialog(context);
                                  if (!context.mounted) return;
                                  if (context.read<ShiftCubit>().state
                                      is! ShiftActive) {
                                    return;
                                  }
                                }
                                await showPaymentModal(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          disabledBackgroundColor: AppColors.surfaceDim,
                          disabledForegroundColor: AppColors.outline,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payments_rounded, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              state.items.isNotEmpty
                                  ? 'Bayar (${formatRupiah(state.grandTotal)})'
                                  : 'Bayar',
                              style: AppTypography.labelMd.copyWith(
                                fontSize: 15,
                                letterSpacing: 0.2,
                                color: state.items.isNotEmpty
                                    ? AppColors.onPrimary
                                    : AppColors.outline,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderTypeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OrderTypeTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 34,
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? AppColors.primaryStrong
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelXs.copyWith(
                color: selected
                    ? AppColors.primaryStrong
                    : AppColors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
