import 'package:intl/intl.dart';

int? parseBillingMinor(String value) {
  final match = RegExp(
    r'^(\d{1,10})(?:\.(\d{1,2}))?$',
  ).firstMatch(value.trim());
  if (match == null) return null;
  return int.parse(match[1]!) * 100 +
      int.parse((match[2] ?? '').padRight(2, '0'));
}

String billingDecimal(int minor) =>
    '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';

String billingAmount(int minor) =>
    'EGP ${NumberFormat.decimalPattern('en').format(minor ~/ 100)}.${(minor % 100).toString().padLeft(2, '0')}';

int billingNet(int gross, int discountBps) {
  final BigInt scaled = BigInt.from(gross) * BigInt.from(10000 - discountBps);
  return ((scaled + BigInt.from(5000)) ~/ BigInt.from(10000)).toInt();
}

String billingDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);
