import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_invoice.dart';
import 'package:spine_clinic_app/features/payments/domain/billing_repository.dart';

const patient = 'Alexander James Montgomery-Wellington';
final row = <String, dynamic>{
  'id': 'invoice-fixture',
  'number': 12,
  'patient_id': 'patient-fixture',
  'patient_name': patient,
  'file_number': 37,
  'doctor_id': 'doctor-fixture',
  'doctor_name': 'Dr. Noura Hassan',
  'branch': 'tagamoa',
  'service_date': '2026-11-10',
  'issued_at': '2026-11-10T10:15:00Z',
  'version': 3,
  'discount_bps': 0,
  'total_minor': 100000,
  'collected_minor': 60000,
  'credited_minor': 0,
  'refunded_minor': 0,
  'outstanding_minor': 40000,
  'refundable_minor': 0,
  'lines': [
    {
      'id': 'line-fixture',
      'item_id': 'item-fixture',
      'item_name': 'Physiotherapy session',
      'quantity': 2,
      'price_minor': 50000,
      'net_minor': 100000,
    },
  ],
  'movements': [
    {
      'id': 'receipt-fixture',
      'number': 8,
      'kind': 'receipt',
      'amount_minor': 60000,
      'debt_reduced_minor': 0,
      'method': 'cash',
      'actor_name': 'Test cashier',
      'recorded_at': '2026-11-10T10:20:00Z',
      'allocations': [
        {'line_id': 'line-fixture', 'amount_minor': 60000},
      ],
    },
  ],
};

class BillingFixture implements BillingRepository {
  BillingFixture({this.empty = false, this.error = false});
  final bool empty, error;
  final invoiceData = BillingInvoice.fromJson(row);
  BillingCommand? lastCommand;
  BillingFilter? lastFilter;
  @override
  Future<Result<List<BillingInvoice>>> invoices(
    BillingFilter filter,
    int offset,
    int limit,
  ) async {
    lastFilter = filter;
    return error
        ? const Result.failure(
            NetworkException(code: 'offline', message: 'Fixture offline'),
          )
        : Result.success(empty ? [] : [invoiceData]);
  }

  @override
  Future<Result<BillingInvoice>> invoice(String id) async =>
      Result.success(invoiceData);
  @override
  Future<Result<List<BillingItem>>> catalog(
    String query, {
    required bool activeOnly,
    int offset = 0,
    int limit = 100,
    List<String> excluded = const [],
  }) async => const Result.success([
    BillingItem(
      id: 'item-fixture',
      name: 'Physiotherapy session',
      price: 50000,
      active: true,
      version: 1,
    ),
  ]);
  @override
  Future<Result<List<BillingItem>>> items(List<String> ids) =>
      catalog('', activeOnly: true);
  @override
  Future<Result<List<BillingParty>>> lookup(
    BillingLookup kind,
    String query,
    int offset,
    int limit,
  ) async => Result.success([
    kind == BillingLookup.patient
        ? BillingParty(
            'patient-fixture',
            patient,
            fileNumber: 37,
            branch: invoiceData.branch,
          )
        : invoiceData.doctor,
  ]);
  @override
  Future<Result<BillingCommit>> execute(BillingCommand command) async {
    lastCommand = command;
    return const Result.failure(
      NetworkException(code: 'mutation/unconfirmed', message: 'Response lost'),
    );
  }

  @override
  Future<Result<BillingCommit?>> recover(
    BillingAction action,
    String subject,
  ) async => const Result.success((
    invoiceId: 'invoice-fixture',
    documentId: 'receipt-fixture',
  ));
  @override
  Future<Result<String>> export(
    BillingFilter filter, {
    required bool collections,
  }) async => const Result.success('');
}
