import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/transaction_model.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/checkout/checkout_cubit.dart';
import '../../utils/currency_formatter.dart';

Future<void> showPaymentModal(BuildContext context) async {
  final cartState = context.read<CartCubit>().state;
  if (cartState.items.isEmpty) return;

  String paymentMethod = 'cash';
  final receivedController =
      TextEditingController(text: cartState.grandTotalIdr.toString());
  final promoController =
      TextEditingController(text: cartState.promoCode ?? '');

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final currentCart = context.watch<CartCubit>().state;
          final checkoutState = context.watch<CheckoutCubit>().state;
          final isProcessing = checkoutState is CheckoutProcessing;

          final received = int.tryParse(receivedController.text
                  .replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;
          final change = paymentMethod == 'cash'
              ? (received - currentCart.grandTotalIdr)
              : 0;
          final canPay = !isProcessing &&
              (paymentMethod != 'cash' ||
                  received >= currentCart.grandTotalIdr);

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_rounded,
                    color: AppColors.primaryStrong,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Proses Pembayaran'),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Bill Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Tagihan',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currentCart.totalItemCount} Item · ${currentCart.orderTypeLabel}',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.onPrimaryContainer
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formatRupiah(currentCart.grandTotalIdr),
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text('Metode Pembayaran', style: AppTypography.labelSm),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _methodChip('cash', 'Tunai', Icons.payments_outlined,
                            paymentMethod, (v) {
                          setState(() {
                            paymentMethod = v;
                            receivedController.text =
                                currentCart.grandTotalIdr.toString();
                          });
                        }),
                        _methodChip('qris', 'QRIS', Icons.qr_code_2_rounded,
                            paymentMethod, (v) {
                          setState(() => paymentMethod = v);
                        }),
                        _methodChip('debit', 'Debit', Icons.credit_card_rounded,
                            paymentMethod, (v) {
                          setState(() => paymentMethod = v);
                        }),
                        _methodChip('bank_transfer', 'Transfer',
                            Icons.account_balance_rounded, paymentMethod, (v) {
                          setState(() => paymentMethod = v);
                        }),
                      ],
                    ),

                    if (paymentMethod == 'cash') ...[
                      const SizedBox(height: 18),
                      Text('Uang Diterima (IDR)', style: AppTypography.labelSm),
                      const SizedBox(height: 6),
                      TextField(
                        controller: receivedController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          prefixText: 'Rp ',
                          hintText: '0',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ActionChip(
                            label: const Text('Uang Pas'),
                            backgroundColor: AppColors.surfaceContainerLow,
                            side: const BorderSide(
                                color: AppColors.outlineVariant),
                            onPressed: () {
                              receivedController.text =
                                  currentCart.grandTotalIdr.toString();
                              setState(() {});
                            },
                          ),
                          for (final nominal in [20000, 50000, 100000])
                            ActionChip(
                              label: Text(formatRupiah(nominal)),
                              backgroundColor: AppColors.surfaceContainerLow,
                              side: const BorderSide(
                                  color: AppColors.outlineVariant),
                              onPressed: () {
                                receivedController.text = nominal.toString();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: change >= 0
                              ? AppColors.successBg
                              : AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              change >= 0 ? 'Kembalian' : 'Kurang Bayar',
                              style: AppTypography.labelMd.copyWith(
                                color: change >= 0
                                    ? AppColors.primaryStrong
                                    : AppColors.errorStrong,
                                letterSpacing: 0.1,
                              ),
                            ),
                            Text(
                              formatRupiah(change.abs()),
                              style: AppTypography.headlineSm.copyWith(
                                color: change >= 0
                                    ? AppColors.primaryStrong
                                    : AppColors.errorStrong,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    Text('Kode Promo (opsional)', style: AppTypography.labelSm),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: promoController,
                            decoration: const InputDecoration(
                              hintText: 'TERATUR10',
                              isDense: true,
                              prefixIcon: Icon(Icons.local_offer_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              final ok = context
                                  .read<CartCubit>()
                                  .applyPromoCode(promoController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? 'Promo TERATUR10 (10%) diterapkan'
                                      : 'Kode promo tidak valid'),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryStrong,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Pakai'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: canPay
                    ? () {
                        Navigator.pop(dialogCtx);
                        context.read<CheckoutCubit>().processPayment(
                              items: currentCart.items,
                              orderType: currentCart.orderType,
                              paymentMethod: paymentMethod,
                              discountIdr: currentCart.discountAmountIdr,
                              taxIdr: currentCart.taxAmountIdr,
                              amountReceivedIdr: paymentMethod == 'cash'
                                  ? received
                                  : currentCart.grandTotalIdr,
                              customerName: currentCart.customerName,
                            );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Bayar Sekarang'),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _methodChip(
  String value,
  String label,
  IconData icon,
  String current,
  ValueChanged<String> onSelect,
) {
  final selected = value == current;
  return InkWell(
    onTap: () => onSelect(value),
    borderRadius: BorderRadius.circular(12),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryContainer
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected
                ? AppColors.primaryStrong
                : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: selected
                  ? AppColors.onPrimaryContainer
                  : AppColors.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showReceiptModal(
    BuildContext context, TransactionModel tx) async {
  await showDialog(
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
                Icons.receipt_long_rounded,
                color: AppColors.primaryStrong,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Struk Transaksi'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tx.isOfflinePending
                    ? AppColors.warningBg
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tx.isOfflinePending ? 'Offline (Antre Sync)' : 'Synced',
                style: AppTypography.labelSm.copyWith(
                  color: tx.isOfflinePending
                      ? AppColors.warningText
                      : AppColors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 390,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.noNota, style: AppTypography.headlineSm),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(tx.soldAt.toLocal()),
                        style: AppTypography.bodySm,
                      ),
                      if (tx.customerName != null &&
                          tx.customerName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Pelanggan: ${tx.customerName}',
                          style: AppTypography.bodySm,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final item in tx.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.qty}x ${item.name}',
                            style: AppTypography.bodyMd.copyWith(fontSize: 14),
                          ),
                        ),
                        Text(
                          formatRupiah(item.lineTotalIdr),
                          style: AppTypography.bodyMd.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 22),
                _receiptRow('Subtotal', formatRupiah(tx.subtotalIdr)),
                if (tx.taxIdr > 0)
                  _receiptRow('Pajak', formatRupiah(tx.taxIdr)),
                if (tx.discountIdr > 0)
                  _receiptRow('Diskon', '-${formatRupiah(tx.discountIdr)}'),
                const SizedBox(height: 6),
                _receiptRow('Total', formatRupiah(tx.totalIdr), bold: true),
                if (tx.paymentMethod == 'cash') ...[
                  const SizedBox(height: 4),
                  _receiptRow('Dibayar', formatRupiah(tx.amountReceivedIdr)),
                  _receiptRow('Kembalian', formatRupiah(tx.changeIdr)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Selesai'),
            ),
          ),
        ],
      );
    },
  );
}

Widget _receiptRow(String label, String value, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold
              ? AppTypography.labelMd.copyWith(letterSpacing: 0)
              : AppTypography.bodySm,
        ),
        Text(
          value,
          style: bold
              ? AppTypography.headlineSm.copyWith(
                  color: AppColors.primaryStrong,
                  fontWeight: FontWeight.w800,
                )
              : AppTypography.bodyMd.copyWith(fontSize: 14),
        ),
      ],
    ),
  );
}
