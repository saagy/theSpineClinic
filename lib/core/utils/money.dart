import 'formatters.dart';

/// Amounts are stored as integer piasters (minor units) everywhere.
abstract final class Money {
  /// Parses a typed EGP amount with up to two decimals, such as `2400` or
  /// `2,400.50`. Returns null for anything else.
  static int? parseMinor(String text) {
    final match = RegExp(
      r'^(\d{1,9})(?:\.(\d{1,2}))?$',
    ).firstMatch(text.trim().replaceAll(',', ''));
    if (match == null) return null;
    return int.parse(match[1]!) * 100 +
        int.parse((match[2] ?? '').padRight(2, '0'));
  }

  /// Plain editable text for a stored amount: `2400` or `2400.50`.
  static String editable(int minor) => minor % 100 == 0
      ? '${minor ~/ 100}'
      : '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';

  /// Display text in the app's currency style: `2,400 EGP`.
  static String format(int minor) => Formatters.formatCurrency(minor / 100);
}
