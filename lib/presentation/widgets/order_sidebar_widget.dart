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

  Future<void> _showOrderInfoDialog(
      BuildContext context, CartState state) async {
    final nameController = TextEditingController(text: state.customerName);
    String orderType = state.orderType;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
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
                      Icons.person_outline_rounded,
                      color: AppColors.primaryStrong,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Info Pelanggan & Order'),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nama Pelanggan / Meja', style: AppTypography.labelSm),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Walk-in Customer / Meja 01',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Tipe Order', style: AppTypography.labelSm),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'dine_in',
                            icon: Icon(Icons.restaurant_rounded, size: 16),
                            label: Text('Dine In'),
                          ),
                          ButtonSegment(
                            value: 'takeaway',
                            icon: Icon(Icons.takeout_dining_rounded, size: 16),
                            label: Text('Takeaway'),
                          ),
                          ButtonSegment(
                            value: 'delivery',
                            icon: Icon(Icons.delivery_dining_rounded, size: 16),
                            label: Text('Delivery'),
                          ),
                        ],
                        selected: {orderType},
                        onSelectionChanged: (val) =>
                            setState(() => orderType = val.first),
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
                          orderType: orderType,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final sidebarWidth = screenWidth >= 1200 ? 410.0 : 370.0;

    return Container(
      width: sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                child: Row(
                  children: [
                    Text('Order Detail', style: AppTypography.headlineSm),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${state.totalItemCount} Items',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (state.items.isNotEmpty)
                      TextButton.icon(
                        onPressed: () =>
                            context.read<CartCubit>().clearCart(),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.errorStrong,
                        ),
                        label: Text(
                          'Clear All',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.errorStrong,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.dangerBg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Customer & Order Type Selector Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => _showOrderInfoDialog(context, state),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 20,
                              color: AppColors.primaryStrong,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMd.copyWith(
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    state.orderTypeLabel,
                                    style: AppTypography.labelSm.copyWith(
                                      fontSize: 11,
                                      color: AppColors.primaryStrong,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primaryStrong,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Cart Item List
              Expanded(
                child: state.items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 36,
                                  color: AppColors.outline,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Keranjang masih kosong',
                                style: AppTypography.headlineSm.copyWith(
                                  fontSize: 17,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pilih menu di sebelah kiri untuk menambahkan pesanan.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySm,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cartItem = state.items[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cartItem.product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodyMd.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatRupiah(cartItem.product.price),
                                        style: AppTypography.labelSm,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Inline Stepper
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => context
                                            .read<CartCubit>()
                                            .removeFromCart(
                                                cartItem.product.id),
                                        borderRadius: BorderRadius.circular(7),
                                        child: const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: Icon(
                                            Icons.remove_rounded,
                                            size: 16,
                                            color: AppColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(
                                          '${cartItem.quantity}',
                                          style: AppTypography.labelMd.copyWith(
                                            letterSpacing: 0,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => context
                                            .read<CartCubit>()
                                            .addToCart(cartItem.product),
                                        borderRadius: BorderRadius.circular(7),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                          child: const Icon(
                                            Icons.add_rounded,
                                            size: 16,
                                            color: AppColors.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 82,
                                  child: Text(
                                    formatRupiah(cartItem.subtotal),
                                    textAlign: TextAlign.right,
                                    style: AppTypography.labelMd.copyWith(
                                      fontSize: 13,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Summary & Checkout Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.outlineVariant, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: AppTypography.bodySm),
                        Text(
                          formatRupiah(state.subTotal),
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                                      ? 'PB1 / Pajak (10%)'
                                      : 'Tanpa Pajak (0%)',
                                  style: AppTypography.labelSm.copyWith(
                                    color: state.includeTax
                                        ? AppColors.onPrimaryContainer
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          formatRupiah(state.taxAmount),
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    if (state.discountAmount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Diskon (${state.promoCode})',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.errorStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '-${formatRupiah(state.discountAmount)}',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.errorStrong,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: AppColors.outlineVariant),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: AppTypography.headlineSm),
                        Text(
                          formatRupiah(state.grandTotal),
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.primaryStrong,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                            const Icon(Icons.payments_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Payment Process',
                              style: AppTypography.labelMd.copyWith(
                                fontSize: 16,
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
