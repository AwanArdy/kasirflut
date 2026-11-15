import 'package:intl/intl.dart';

String formatRupiah(num amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

String formatNumber(num amount) {
  final formatter = NumberFormat.decimalPattern('id_ID');
  return formatter.format(amount);
}
