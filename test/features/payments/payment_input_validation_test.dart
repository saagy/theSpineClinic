import 'package:flutter_test/flutter_test.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_input_parsers.dart';

void main() {
  test('rejects non-finite, nonpositive and malformed payment amounts', () {
    for (final value in [
      'NaN',
      'Infinity',
      '-Infinity',
      '1e999',
      '0',
      '-1',
      'abc',
      '',
    ]) {
      expect(
        readPositiveAmount(
          value,
          emptyMessage: AppStrings.amountRequired,
        ).value,
        isNull,
        reason: value,
      );
    }
    expect(
      readPositiveAmount(
        ' 125.50 ',
        emptyMessage: AppStrings.amountRequired,
      ).value,
      125.5,
    );
  });
  test('service totals cannot be below the amount already paid', () {
    expect(
      readServiceTotal('100', 101).error,
      AppStrings.amountExceedsServiceTotal,
    );
    expect(readServiceTotal('100', 100).value, 100);
    expect(readServiceTotal('Infinity', 100).value, isNull);
  });
}
