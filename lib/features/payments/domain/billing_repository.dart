import '../../../core/errors/result.dart';
import '../../patient/domain/clinic_location.dart';
import 'billing_invoice.dart';
import 'billing_money.dart';

enum BillingStatus { draft, outstanding, settled }

enum BillingLookup { patient, doctor, senior }

typedef BillingFilter = ({
  String query,
  ClinicLocation? branch,
  BillingStatus? status,
  DateTime? from,
  DateTime? to,
});
const BillingFilter emptyBillingFilter = (
  query: '',
  branch: null,
  status: null,
  from: null,
  to: null,
);

class BillingDraftLine {
  const BillingDraftLine(this.item, this.quantity);
  final BillingItem item;
  final int quantity;

  BillingRow toJson() => {
    'item_id': item.id,
    'quantity': quantity,
    'price_minor': item.price,
    'item_name': item.name,
  };
}

class BillingCommand {
  BillingCommand._(this.action, this.subject, this.payload);

  factory BillingCommand.item(
    BillingItem? item,
    String name,
    int price,
    bool active,
  ) => BillingCommand._(BillingAction.item, item?.id ?? 'new', {
    'id': item?.id,
    'version': item?.version,
    'name': name,
    'price_minor': price,
    'active': active,
  });

  factory BillingCommand.draft({
    BillingInvoice? invoice,
    required BillingParty patient,
    required BillingParty doctor,
    BillingParty? consultant,
    required ClinicLocation branch,
    required DateTime date,
    required int discount,
    required List<BillingDraftLine> lines,
  }) => BillingCommand._(BillingAction.draft, invoice?.id ?? 'new', {
    'id': invoice?.id,
    'version': invoice?.version,
    'patient_id': patient.id,
    'doctor_id': doctor.id,
    'consultant_id': consultant?.id,
    'branch': branch.dbValue,
    'service_date': billingDate(date),
    'discount_bps': discount,
    'lines': lines.map((line) => line.toJson()).toList(),
  });

  factory BillingCommand.issue(BillingInvoice invoice) => BillingCommand._(
    BillingAction.issue,
    invoice.id,
    {'id': invoice.id, 'version': invoice.version},
  );

  factory BillingCommand.money(
    BillingAction action,
    BillingInvoice invoice,
    int amount,
    BillingMethod method,
    String? reason,
  ) => BillingCommand._(action, invoice.id, {
    'id': invoice.id,
    'version': invoice.version,
    'amount_minor': amount,
    'method': method.name,
    'reason': reason,
  });

  factory BillingCommand.credit(
    BillingInvoice invoice,
    Map<String, int> quantities,
    String reason,
  ) => BillingCommand._(BillingAction.credit, invoice.id, {
    'id': invoice.id,
    'version': invoice.version,
    'reason': reason,
    'lines': quantities.entries
        .map((entry) => {'line_id': entry.key, 'quantity': entry.value})
        .toList(),
  });

  final BillingAction action;
  final String subject;
  final BillingRow payload;
}

typedef BillingCommit = ({String? invoiceId, String? documentId});

abstract interface class BillingRepository {
  Future<Result<List<BillingItem>>> catalog(
    String query, {
    required bool activeOnly,
    int offset = 0,
    int limit = 100,
    List<String> excluded = const [],
  });
  Future<Result<List<BillingItem>>> items(List<String> ids);
  Future<Result<List<BillingParty>>> lookup(BillingLookup kind, String query, int offset, int limit);
  Future<Result<List<BillingInvoice>>> invoices(
    BillingFilter filter,
    int offset,
    int limit,
  );
  Future<Result<BillingInvoice>> invoice(String id);
  Future<Result<BillingCommit>> execute(BillingCommand command);
  Future<Result<BillingCommit?>> recover(BillingAction action, String subject);
  Future<Result<String>> export(
    BillingFilter filter, {
    required bool collections,
  });
}
