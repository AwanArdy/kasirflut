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
            title: const Text('Proses Pembayaran'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Tagihan',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            formatRupiah(currentCart.grandTotalIdr),
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Metode Pembayaran', style: AppTypography.labelMd),
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
                        _methodChip('qris', 'QRIS', Icons.qr_code_2,
                            paymentMethod, (v) {
                          setState(() => paymentMethod = v);
                        }),
                        _methodChip('debit', 'Debit', Icons.credit_card,
                            paymentMethod, (v) {
                          setState(() => paymentMethod = v);
                        }),
                        _methodChip('bank_transfer', 'Transfer',
                            Icons.account_balance, paymentMethod, (v) {
                          setState(() => paymentMethod = v);
                        }),
                      ],
                    ),
                    if (paymentMethod == 'cash') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: receivedController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Uang Diterima (IDR)',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Uang Pas'),
                            onPressed: () {
                              receivedController.text =
                                  currentCart.grandTotalIdr.toString();
                              setState(() {});
                            },
                          ),
                          for (final nominal in [20000, 50000, 100000])
                            ActionChip(
                              label: Text(formatRupiah(nominal)),
                              onPressed: () {
                                receivedController.text = nominal.toString();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kembalian:', style: AppTypography.bodyMd),
                          Text(
                            change >= 0
                                ? formatRupiah(change)
                                : 'Kurang ${formatRupiah(change.abs())}',
                            style: AppTypography.headlineSm.copyWith(
                              color: change >= 0
                                  ? AppColors.primaryStrong
                                  : AppColors.errorStrong,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: promoController,
                            decoration: const InputDecoration(
                              labelText: 'Kode Promo (opsional)',
                              hintText: 'TERATUR10',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
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
                          child: const Text('Pakai'),
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
  return ChoiceChip(
    selected: selected,
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label),
      ],
    ),
    onSelected: (_) => onSelect(value),
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
            const Icon(Icons.receipt_long, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Struk Transaksi'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tx.noNota, style: AppTypography.headlineSm),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(tx.soldAt.toLocal()),
                  style: AppTypography.bodySm,
                ),
                if (tx.customerName != null && tx.customerName!.isNotEmpty)
                  Text('Pelanggan: ${tx.customerName}',
                      style: AppTypography.bodySm),
                const Divider(height: 20),
                for (final item in tx.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.qty}x ${item.name}',
                            style: AppTypography.bodyMd,
                          ),
                        ),
                        Text(
                          formatRupiah(item.lineTotalIdr),
                          style: AppTypography.bodyMd,
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 20),
                _receiptRow('Subtotal', formatRupiah(tx.subtotalIdr)),
                if (tx.taxIdr > 0)
                  _receiptRow('Pajak', formatRupiah(tx.taxIdr)),
                if (tx.discountIdr > 0)
                  _receiptRow('Diskon', '-${formatRupiah(tx.discountIdr)}'),
                _receiptRow('Total', formatRupiah(tx.totalIdr), bold: true),
                if (tx.paymentMethod == 'cash') ...[
                  _receiptRow('Dibayar', formatRupiah(tx.amountReceivedIdr)),
                  _receiptRow('Kembalian', formatRupiah(tx.changeIdr)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: const Text('Selesai'),
          ),
        ],
      );
    },
  );
}

Widget _receiptRow(String label, String value, {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: bold ? AppTypography.labelMd : AppTypography.bodySm),
        Text(
          value,
          style: bold ? AppTypography.headlineSm : AppTypography.bodyMd,
        ),
      ],
    ),
  );
}
