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
              title: const Text('Info Pelanggan & Tipe Order'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pelanggan / Meja',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Tipe Order', style: AppTypography.labelMd),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'dine_in', label: Text('Dine In')),
                        ButtonSegment(
                            value: 'takeaway', label: Text('Takeaway')),
                        ButtonSegment(
                            value: 'delivery', label: Text('Delivery')),
                      ],
                      selected: {orderType},
                      onSelectionChanged: (val) =>
                          setState(() => orderType = val.first),
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
    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
            left: BorderSide(color: AppColors.outlineVariant, width: 1)),
      ),
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text('Order Detail', style: AppTypography.headlineSm),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${state.totalItemCount} Items',
                        style: AppTypography.labelSm
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    const Spacer(),
                    if (state.items.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            context.read<CartCubit>().clearCart(),
                        child: Text('Clear All',
                            style: TextStyle(color: AppColors.error)),
                      ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showOrderInfoDialog(context, state),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 20, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${state.customerName} · ${state.orderTypeLabel}',
                          style: AppTypography.labelMd,
                        ),
                      ),
                      const Icon(Icons.edit_outlined,
                          size: 18, color: AppColors.primaryStrong),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: state.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart_outlined,
                                size: 64, color: AppColors.outlineVariant),
                            const SizedBox(height: 12),
                            Text('Keranjang masih kosong',
                                style: AppTypography.bodyMd
                                    .copyWith(color: AppColors.outline)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) =>
                            const Divider(color: AppColors.outlineVariant),
                        itemBuilder: (context, index) {
                          final cartItem = state.items[index];
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cartItem.product.name,
                                      style: AppTypography.bodyMd
                                          .copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${cartItem.quantity}x @ ${formatRupiah(cartItem.product.price)}',
                                      style: AppTypography.bodySm,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatRupiah(cartItem.subtotal),
                                style: AppTypography.labelMd
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: AppColors.outline),
                                onPressed: () => context
                                    .read<CartCubit>()
                                    .removeFromCart(cartItem.product.id),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                      top: BorderSide(
                          color: AppColors.outlineVariant, width: 1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: AppTypography.bodySm),
                        Text(formatRupiah(state.subTotal),
                            style: AppTypography.bodyMd),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => context
                              .read<CartCubit>()
                              .toggleTax(!state.includeTax),
                          child: Row(
                            children: [
                              Text(
                                state.includeTax
                                    ? 'PB1 / Pajak (10%)'
                                    : 'Tanpa Pajak (0%)',
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.primaryStrong,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(formatRupiah(state.taxAmount),
                            style: AppTypography.bodyMd),
                      ],
                    ),
                    if (state.discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Diskon (${state.promoCode})',
                              style: AppTypography.bodySm
                                  .copyWith(color: AppColors.errorStrong)),
                          Text('-${formatRupiah(state.discountAmount)}',
                              style: AppTypography.bodyMd
                                  .copyWith(color: AppColors.errorStrong)),
                        ],
                      ),
                    ],
                    const Divider(height: 24, color: AppColors.outlineVariant),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: AppTypography.headlineSm),
                        Text(
                          formatRupiah(state.grandTotal),
                          style: AppTypography.headlineMd
                              .copyWith(color: AppColors.primaryStrong),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Payment Process',
                          style: AppTypography.labelMd.copyWith(
                            fontSize: 18,
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
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
