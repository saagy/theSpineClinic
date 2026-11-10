import '../../../core/constants/app_strings.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';

String billingCsv(List<BillingRow> rows, {required bool collections}) {
  final headers = collections
      ? [
          AppStrings.billing.document,
          AppStrings.billing.number,
          AppStrings.billing.invoice,
          AppStrings.billing.branch,
          AppStrings.billing.file,
          AppStrings.billing.patient,
          AppStrings.billing.doctor,
          AppStrings.billing.recordedAt,
          AppStrings.billing.method,
          AppStrings.billing.amount,
        ]
      : [
          AppStrings.billing.invoice,
          AppStrings.billing.branch,
          AppStrings.billing.file,
          AppStrings.billing.patient,
          AppStrings.billing.doctor,
          AppStrings.billing.serviceDate,
          AppStrings.billing.total,
          AppStrings.billing.collected,
          AppStrings.billing.credited,
          AppStrings.billing.refunded,
          AppStrings.billing.outstanding,
          AppStrings.billing.refundable,
        ];
  final csv = StringBuffer('\ufeff')..write(_row(headers));
  for (final row in rows) {
    final branch = parseBillingBranch(row['branch'] as String)?.displayLabel;
    csv.write(
      _row(
        collections
            ? [
                row['kind'],
                row['number'],
                row['invoice_number'],
                branch,
                row['file_number'],
                row['patient_name'],
                row['doctor_name'],
                row['recorded_at'],
                row['method'],
                billingDecimal(row['amount_minor'] as int),
              ]
            : [
                row['number'] ?? AppStrings.billing.draft,
                branch,
                row['file_number'],
                row['patient_name'],
                row['doctor_name'],
                row['service_date'],
                for (final key in [
                  'total',
                  'collected',
                  'credited',
                  'refunded',
                  'outstanding',
                  'refundable',
                ])
                  billingDecimal(row['${key}_minor'] as int),
              ],
      ),
    );
  }
  return csv.toString();
}

String _row(List<Object?> cells) => '${cells.map(_cell).join(',')}\r\n';

String _cell(Object? value) {
  String text = value?.toString() ?? '';
  if (RegExp(r'^\s*[=+\-@]').hasMatch(text) ||
      text.startsWith('\t') ||
      text.startsWith('\r') ||
      text.startsWith('\n')) {
    text = "'$text";
  }
  return '"${text.replaceAll('"', '""')}"';
}
