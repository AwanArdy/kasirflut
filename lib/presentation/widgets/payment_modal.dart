import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/transaction_model.dart';
import '../../logic/auth/auth_cubit.dart';
import '../../logic/cart/cart_cubit.dart';
import '../../logic/checkout/checkout_cubit.dart';
import '../../utils/currency_formatter.dart';

/// Formatter ribuan otomatis untuk input nominal uang tunai (contoh: 100000 -> 100.000)
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = NumberFormat('#,###', 'id_ID').format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Modal Proses Pembayaran (Tunai, QRIS, Debit, Transfer + Promo)
Future<void> showPaymentModal(BuildContext context) async {
  final cartState = context.read<CartCubit>().state;
  if (cartState.items.isEmpty) return;

  String paymentMethod = 'cash';
  final receivedController = TextEditingController(
    text: NumberFormat('#,###', 'id_ID').format(cartState.grandTotalIdr),
  );
  final promoController =
      TextEditingController(text: cartState.promoCode ?? '');

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.onSurface.withValues(alpha: 0.42),
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final currentCart = context.watch<CartCubit>().state;
          final checkoutState = context.watch<CheckoutCubit>().state;
          final isProcessing = checkoutState is CheckoutProcessing;

          final received = int.tryParse(
                receivedController.text.replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
              0;
          final change = paymentMethod == 'cash'
              ? (received - currentCart.grandTotalIdr)
              : 0;
          final canPay = !isProcessing &&
              (paymentMethod != 'cash' ||
                  received >= currentCart.grandTotalIdr);

          final breakdownParts = <String>[
            'Subtotal ${formatRupiah(currentCart.subTotalIdr)}',
            if (currentCart.discountAmountIdr > 0)
              'Diskon -${formatRupiah(currentCart.discountAmountIdr)}',
            if (currentCart.includeTax)
              'PB1 (10%) ${formatRupiah(currentCart.taxAmountIdr)}',
          ];

          return Dialog(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Modal
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.primaryStrong,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pembayaran',
                                style: AppTypography.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currentCart.customerName} • ${currentCart.orderTypeLabel} • ${currentCart.totalItemCount} Items',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSm,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: isProcessing
                              ? null
                              : () => Navigator.pop(dialogCtx),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 2. Banner Total Tagihan
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'Total Tagihan',
                                style: AppTypography.labelSm.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                formatRupiah(currentCart.grandTotalIdr),
                                style: AppTypography.headlineLg.copyWith(
                                  color: AppColors.primaryStrong,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            breakdownParts.join(' • '),
                            style: AppTypography.labelSm,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. Pilihan Metode Pembayaran (Grid 4 Kolom)
                    Text(
                      'Metode Pembayaran',
                      style: AppTypography.labelSm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentMethodTile(
                            value: 'cash',
                            label: 'Tunai',
                            icon: Icons.payments_rounded,
                            selected: paymentMethod == 'cash',
                            onTap: () {
                              setState(() {
                                paymentMethod = 'cash';
                                receivedController.text =
                                    NumberFormat('#,###', 'id_ID')
                                        .format(currentCart.grandTotalIdr);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PaymentMethodTile(
                            value: 'qris',
                            label: 'QRIS',
                            icon: Icons.qr_code_2_rounded,
                            selected: paymentMethod == 'qris',
                            onTap: () => setState(() => paymentMethod = 'qris'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PaymentMethodTile(
                            value: 'debit',
                            label: 'Debit',
                            icon: Icons.credit_card_rounded,
                            selected: paymentMethod == 'debit',
                            onTap: () =>
                                setState(() => paymentMethod = 'debit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PaymentMethodTile(
                            value: 'bank_transfer',
                            label: 'Transfer',
                            icon: Icons.account_balance_rounded,
                            selected: paymentMethod == 'bank_transfer',
                            onTap: () =>
                                setState(() => paymentMethod = 'bank_transfer'),
                          ),
                        ),
                      ],
                    ),

                    // 4. Input Uang Diterima & Kembalian (Khusus Tunai)
                    if (paymentMethod == 'cash') ...[
                      const SizedBox(height: 18),
                      Text(
                        'Uang Diterima',
                        style: AppTypography.labelSm.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: receivedController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_ThousandsFormatter()],
                        onChanged: (_) => setState(() {}),
                        textAlign: TextAlign.right,
                        style: AppTypography.headlineSm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14, right: 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Rp',
                                  style: AppTypography.headlineSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 0, minHeight: 0),
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryContainer,
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryContainer,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Chip Nominal Cepat
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickCashChip(
                            label: 'Uang Pas',
                            selected: received == currentCart.grandTotalIdr,
                            onTap: () {
                              setState(() {
                                receivedController.text =
                                    NumberFormat('#,###', 'id_ID')
                                        .format(currentCart.grandTotalIdr);
                              });
                            },
                          ),
                          for (final nominal in [20000, 50000, 100000])
                            _QuickCashChip(
                              label: formatRupiah(nominal),
                              selected: received == nominal &&
                                  nominal != currentCart.grandTotalIdr,
                              onTap: () {
                                setState(() {
                                  receivedController.text =
                                      NumberFormat('#,###', 'id_ID')
                                          .format(nominal);
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Indikator Kembalian / Kurang Bayar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: change >= 0
                              ? AppColors.surfaceContainer
                              : AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  change >= 0
                                      ? Icons.check_circle_rounded
                                      : Icons.error_rounded,
                                  size: 20,
                                  color: change >= 0
                                      ? AppColors.primaryStrong
                                      : AppColors.errorStrong,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  change >= 0 ? 'Kembalian' : 'Kurang Bayar',
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.onSurface,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              formatRupiah(change.abs()),
                              style: AppTypography.headlineSm.copyWith(
                                color: change >= 0
                                    ? AppColors.primaryStrong
                                    : AppColors.errorStrong,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // 5. Kode Promo (Opsional)
                    Text(
                      'Kode Promo (Opsional)',
                      style: AppTypography.labelSm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.only(left: 12, right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              AppColors.outlineVariant.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            size: 18,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: promoController,
                              textCapitalization: TextCapitalization.characters,
                              onSubmitted: (val) {
                                final ok = context
                                    .read<CartCubit>()
                                    .applyPromoCode(val);
                                if (ok && paymentMethod == 'cash') {
                                  final updatedTotal = context
                                      .read<CartCubit>()
                                      .state
                                      .grandTotalIdr;
                                  setState(() {
                                    receivedController.text =
                                        NumberFormat('#,###', 'id_ID')
                                            .format(updatedTotal);
                                  });
                                }
                              },
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Masukkan kode promo',
                                hintStyle: AppTypography.bodySm.copyWith(
                                  color: AppColors.outline,
                                ),
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              if (currentCart.promoCode == 'TERATUR10') {
                                context.read<CartCubit>().clearPromoCode();
                                promoController.clear();
                              } else {
                                final targetCode =
                                    promoController.text.trim().isEmpty
                                        ? 'TERATUR10'
                                        : promoController.text.trim();
                                final ok = context
                                    .read<CartCubit>()
                                    .applyPromoCode(targetCode);
                                if (ok) {
                                  promoController.text = 'TERATUR10';
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kode promo tidak valid'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                              if (paymentMethod == 'cash') {
                                final updatedTotal = context
                                    .read<CartCubit>()
                                    .state
                                    .grandTotalIdr;
                                setState(() {
                                  receivedController.text =
                                      NumberFormat('#,###', 'id_ID')
                                          .format(updatedTotal);
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: currentCart.promoCode == 'TERATUR10'
                                    ? AppColors.primary
                                    : AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentCart.promoCode == 'TERATUR10'
                                    ? 'TERATUR10 ✓'
                                    : 'TERATUR10 (-10%)',
                                style: AppTypography.labelXs.copyWith(
                                  color: currentCart.promoCode == 'TERATUR10'
                                      ? AppColors.onPrimary
                                      : AppColors.primaryStrong,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 6. Footer / Tombol Aksi
                    Row(
                      children: [
                        TextButton(
                          onPressed: isProcessing
                              ? null
                              : () => Navigator.pop(dialogCtx),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: canPay
                                  ? () {
                                      Navigator.pop(dialogCtx);
                                      context
                                          .read<CheckoutCubit>()
                                          .processPayment(
                                            items: currentCart.items,
                                            orderType: currentCart.orderType,
                                            paymentMethod: paymentMethod,
                                            discountIdr:
                                                currentCart.discountAmountIdr,
                                            taxIdr: currentCart.taxAmountIdr,
                                            amountReceivedIdr:
                                                paymentMethod == 'cash'
                                                    ? received
                                                    : currentCart.grandTotalIdr,
                                            customerName:
                                                currentCart.customerName,
                                          );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.onPrimary,
                                disabledBackgroundColor: AppColors.surfaceDim,
                                disabledForegroundColor: AppColors.outline,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: AppColors.onPrimary,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Bayar Sekarang',
                                          style:
                                              AppTypography.labelMd.copyWith(
                                            color: canPay
                                                ? AppColors.onPrimary
                                                : AppColors.outline,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                          color: canPay
                                              ? AppColors.onPrimary
                                              : AppColors.outline,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _PaymentMethodTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer.withValues(alpha: 0.65)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? AppColors.primaryStrong
                  : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: selected
                    ? AppColors.primaryStrong
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCashChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickCashChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: selected
                ? AppColors.onPrimaryContainer
                : AppColors.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Preferensi auto-print selama sesi aplikasi berjalan
bool _autoPrintNextReceipt = true;

/// Modal Pembayaran Berhasil & Preview Struk Thermal 58mm
Future<void> showReceiptModal(
  BuildContext context,
  TransactionModel tx,
) async {
  final authState = context.read<AuthCubit>().state;
  final outletName = authState is AuthAuthenticated
      ? authState.session.outletName
      : 'Outlet TERATUR POS';
  final cashierName =
      authState is AuthAuthenticated ? authState.session.userName : 'Kasir';

  final orderTypeText = switch (tx.orderType) {
    'takeaway' => 'Takeaway',
    'delivery' => 'Delivery',
    _ => 'Dine In',
  };

  final paymentMethodText = switch (tx.paymentMethod) {
    'qris' => 'QRIS',
    'debit' => 'Kartu Debit',
    'bank_transfer' => 'Transfer Bank',
    _ => 'Tunai',
  };

  final waController = TextEditingController();
  bool isPrinting = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.onSurface.withValues(alpha: 0.45),
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          void showFeedback(String message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          Future<void> handlePrint() async {
            if (isPrinting) return;
            setState(() => isPrinting = true);
            await Future<void>.delayed(const Duration(milliseconds: 650));
            if (!ctx.mounted) return;
            setState(() => isPrinting = false);
            showFeedback(
              'Struk ${tx.noNota} siap dicetak (mode simulasi printer thermal).',
            );
          }

          return Dialog(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 490),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Success State Header
                    Stack(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: InkWell(
                            onTap: () => Navigator.pop(dialogCtx),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.16),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 38,
                                  color: AppColors.primaryStrong,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Pembayaran Berhasil!',
                                style: AppTypography.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Transaksi telah selesai dan data berhasil dicatat.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySm,
                              ),
                              const SizedBox(height: 10),

                              // Sync Pill Status
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: tx.isOfflinePending
                                      ? AppColors.warningBg
                                      : AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tx.isOfflinePending
                                          ? Icons.cloud_off_rounded
                                          : Icons.cloud_done_rounded,
                                      size: 15,
                                      color: tx.isOfflinePending
                                          ? AppColors.warningText
                                          : AppColors.primaryStrong,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tx.isOfflinePending
                                          ? 'Tersimpan Offline • Antre Sync'
                                          : 'Tersinkron ke Cloud & SQLite Lokal',
                                      style: AppTypography.labelXs.copyWith(
                                        color: tx.isOfflinePending
                                            ? AppColors.warningText
                                            : AppColors.primaryStrong,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Order Meta Tags
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      tx.noNota,
                                      style: AppTypography.labelXs.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text('•', style: AppTypography.labelXs),
                                    Text(
                                      '${tx.customerName?.isNotEmpty == true ? tx.customerName : 'Walk-in'} ($orderTypeText)',
                                      style: AppTypography.labelXs,
                                    ),
                                    Text('•', style: AppTypography.labelXs),
                                    Text(
                                      'Kasir: $cashierName',
                                      style: AppTypography.labelXs,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. Thermal Struk Preview Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SLIP BUKTI BAYAR',
                                style: AppTypography.labelXs.copyWith(
                                  color: AppColors.outline,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                'Thermal 58mm',
                                style: AppTypography.labelXs.copyWith(
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'TERATUR POS',
                                  style: AppTypography.headlineSm.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  outletName,
                                  style: AppTypography.labelXs,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd MMM yyyy • HH:mm:ss')
                                      .format(tx.soldAt.toLocal()),
                                  style: AppTypography.labelXs,
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                              height: 1,
                              color: AppColors.outlineVariant,
                            ),
                          ),

                          // Line Items
                          for (final item in tx.items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.qty}x ${item.name}',
                                          style: AppTypography.bodySm.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          '@ ${formatRupiah(item.unitPriceIdr)}',
                                          style: AppTypography.labelXs,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatRupiah(item.lineTotalIdr),
                                    style: AppTypography.bodySm.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(
                              height: 1,
                              color: AppColors.outlineVariant,
                            ),
                          ),

                          // Subtotals
                          _receiptLine('Subtotal', formatRupiah(tx.subtotalIdr)),
                          if (tx.discountIdr > 0) ...[
                            const SizedBox(height: 4),
                            _receiptLine(
                              'Diskon Promo',
                              '-${formatRupiah(tx.discountIdr)}',
                              valueColor: AppColors.primaryStrong,
                            ),
                          ],
                          if (tx.taxIdr > 0) ...[
                            const SizedBox(height: 4),
                            _receiptLine(
                              'PB1 Restoran (10%)',
                              '+${formatRupiah(tx.taxIdr)}',
                            ),
                          ],
                          const SizedBox(height: 8),

                          // Total Akhir Highlight Row
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Pembayaran',
                                  style: AppTypography.headlineSm.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  formatRupiah(tx.totalIdr),
                                  style: AppTypography.headlineMd.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryStrong,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Metode & Kembalian
                          _receiptLine(
                            'Metode Bayar:',
                            paymentMethodText,
                            small: true,
                          ),
                          if (tx.paymentMethod == 'cash') ...[
                            const SizedBox(height: 3),
                            _receiptLine(
                              'Tunai Diterima:',
                              formatRupiah(tx.amountReceivedIdr),
                              small: true,
                            ),
                            const SizedBox(height: 3),
                            _receiptLine(
                              'Kembalian:',
                              formatRupiah(tx.changeIdr),
                              small: true,
                              valueColor: AppColors.primaryStrong,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            'Terima kasih atas kunjungan Anda!\nSimpan struk ini sebagai bukti pembayaran yang sah.',
                            textAlign: TextAlign.center,
                            style: AppTypography.labelXs.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. Kirim Struk Digital
                    Text(
                      'Kirim Struk Digital',
                      style: AppTypography.labelXs.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.only(left: 10, right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.chat_rounded,
                                  size: 18,
                                  color: AppColors.primaryStrong,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: waController,
                                    keyboardType: TextInputType.phone,
                                    style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '08xxxxxxxxxx',
                                      hintStyle: AppTypography.bodySm.copyWith(
                                        color: AppColors.outline,
                                      ),
                                      isDense: true,
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    final phone = waController.text.trim();
                                    if (phone.length < 8) {
                                      showFeedback(
                                        'Masukkan nomor WhatsApp yang valid',
                                      );
                                      return;
                                    }
                                    showFeedback(
                                      'Struk ${tx.noNota} disiapkan untuk WhatsApp $phone',
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Kirim',
                                      style: AppTypography.labelXs.copyWith(
                                        color: AppColors.primaryStrong,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SquareIconButton(
                          icon: Icons.mail_outline_rounded,
                          tooltip: 'Kirim via Email',
                          onTap: () => showFeedback(
                            'Fitur kirim e-Struk via Email segera tersedia',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SquareIconButton(
                          icon: Icons.download_rounded,
                          tooltip: 'Unduh PDF Struk',
                          onTap: () => showFeedback(
                            'e-Struk ${tx.noNota}.pdf siap disimpan',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 4. Toggle Auto-Print Preference
                    InkWell(
                      onTap: () {
                        setState(() {
                          _autoPrintNextReceipt = !_autoPrintNextReceipt;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _autoPrintNextReceipt,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _autoPrintNextReceipt = val ?? true;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Otomatis cetak struk untuk transaksi berikutnya',
                                style: AppTypography.labelSm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 5. Primary Action Buttons
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isPrinting ? null : handlePrint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: isPrinting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.print_rounded, size: 22),
                        label: Text(
                          isPrinting
                              ? 'Mengirim ke Printer Thermal...'
                              : 'Cetak Struk',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 46,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerLow,
                          foregroundColor: AppColors.onSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 19),
                        label: Text(
                          'Transaksi Baru / Selesai',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _receiptLine(
  String label,
  String value, {
  bool small = false,
  Color? valueColor,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: small ? AppTypography.labelXs : AppTypography.labelSm,
      ),
      Text(
        value,
        style: (small ? AppTypography.labelXs : AppTypography.labelSm).copyWith(
          color: valueColor ?? AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
