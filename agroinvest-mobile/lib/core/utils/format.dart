import 'package:intl/intl.dart';

final NumberFormat _moneyFormat = NumberFormat('#,##0', 'uz');

/// "12500000" -> "12 500 000" (uz locale uses space grouping)
String formatMoney(dynamic value) {
  if (value == null) return '0';
  final num? parsed = value is num ? value : num.tryParse(value.toString());
  if (parsed == null) return value.toString();
  return _moneyFormat.format(parsed).replaceAll(',', ' ');
}

String formatMoneySum(dynamic value) => "${formatMoney(value)} so'm";

/// "2026-07-07T09:30:00" -> "07.07.2026"
String formatDate(dynamic isoString) {
  if (isoString == null) return '-';
  final date = DateTime.tryParse(isoString.toString());
  if (date == null) return isoString.toString();
  return DateFormat('dd.MM.yyyy').format(date);
}

/// "2026-07-07T09:30:00" -> "07.07.2026 09:30"
String formatDateTime(dynamic isoString) {
  if (isoString == null) return '-';
  final date = DateTime.tryParse(isoString.toString());
  if (date == null) return isoString.toString();
  return DateFormat('dd.MM.yyyy HH:mm').format(date);
}
