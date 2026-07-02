import 'package:spine_clinic_app/core/constants/app_strings.dart';

class PaymentAmountResult {
  const PaymentAmountResult.value(this.value) : error = null;
  const PaymentAmountResult.error(this.error) : value = null;

  final double? value;
  final String? error;
}

PaymentAmountResult readPositiveAmount(
  String text, {
  required String emptyMessage,
  String positiveMessage = AppStrings.amountMustBePositive,
}) {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) return PaymentAmountResult.error(emptyMessage);
  final double? value = double.tryParse(trimmed);
  if (value == null || value <= 0) {
    return PaymentAmountResult.error(positiveMessage);
  }
  return PaymentAmountResult.value(value);
}

PaymentAmountResult readServiceTotal(String text, double paidAmount) {
  final PaymentAmountResult result = readPositiveAmount(
    text,
    emptyMessage: AppStrings.totalAmountRequired,
    positiveMessage: AppStrings.totalAmountPositive,
  );
  final double? value = result.value;
  if (value == null) return result;
  if (paidAmount > value) {
    return const PaymentAmountResult.error(
      AppStrings.amountExceedsServiceTotal,
    );
  }
  return result;
}

int? readOptionalCredit(String text) {
  final String trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  final int? value = int.tryParse(trimmed);
  if (value == null || value < 0) return null;
  return value;
}
