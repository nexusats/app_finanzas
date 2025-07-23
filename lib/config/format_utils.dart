import 'package:intl/intl.dart';

String formatCurrency(double value) {
  final formatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 2,
  );
  return formatter.format(value);
}
