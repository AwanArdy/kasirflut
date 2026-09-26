import 'package:intl/intl.dart';

String formatRupiah(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

String formatNumber(double amount) {
  final formatter = NumberFormat.decimalPattern('id_ID');
  return formatter.format(amount);
}
