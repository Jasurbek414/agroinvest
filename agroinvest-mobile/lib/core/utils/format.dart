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

/// "12500000" -> "12.5 mln", "500000" -> "500 ming", "2100000000" -> "2.1 mlrd".
/// For tight spots (card progress rows, stat strips) where the full grouped
/// number wouldn't fit next to its label.
String formatMoneyCompact(dynamic value) {
  final num? parsed = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (parsed == null) return '0';

  String trimmed(double v) {
    final s = v.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  final abs = parsed.abs();
  if (abs >= 1000000000) return '${trimmed(parsed / 1000000000)} mlrd';
  if (abs >= 1000000) return '${trimmed(parsed / 1000000)} mln';
  if (abs >= 1000) return '${trimmed(parsed / 1000)} ming';
  return formatMoney(parsed);
}

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
