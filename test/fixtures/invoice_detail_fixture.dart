import 'package:spine_clinic_app/features/payments/domain/invoice_detail.dart';

Map<String, dynamic> _void(String? by) => {
  'voided_at': by == null ? null : '2026-11-10T15:00:00Z',
  'voided_by_name': by,
  'void_reason': by == null ? null : 'Entered on the wrong invoice',
};

Map<String, dynamic> receiptJson(int number, int amount, {String method = 'cash', int hour = 9,
        String? voidedBy, String? replaces}) => {
  'id': 'receipt-$number', 'branch': 'tagamoa', 'number': number, 'amount_minor': amount,
  'method': method, 'received_at': '2026-11-10T${hour.toString().padLeft(2, '0')}:00:00Z',
  'recorded_at': '2026-11-10T${hour.toString().padLeft(2, '0')}:00:00Z',
  'recorded_by_name': 'Nour Mahmoud', 'replaces_receipt_id': replaces, ..._void(voidedBy),
};

Map<String, dynamic> refundJson(int number, {required int value, required int payback,
        int sessions = 0, String line = 'line-1', int hour = 12, String? voidedBy}) => {
  'id': 'refund-$number', 'branch': 'tagamoa', 'number': number, 'value_minor': value,
  'payback_minor': payback, 'payback_method': payback > 0 ? 'cash' : null,
  'reason': 'Patient is travelling', 'recorded_at': '2026-11-10T${hour.toString().padLeft(2, '0')}:00:00Z',
  'recorded_by_name': 'Nour Mahmoud', ..._void(voidedBy),
  'lines': [{'line_id': line, 'sessions_cancelled': sessions, 'value_minor': value}],
};

/// A discount given after issue, all on the PT line; it never cancels sessions.
Map<String, dynamic> discountJson(int number, {required int value, int payback = 0, int hour = 13,
        String? voidedBy}) => {
  ...refundJson(number, value: value, payback: payback, hour: hour, voidedBy: voidedBy),
  'id': 'discount-$number', 'kind': 'discount', 'reason': 'Approved by the head receptionist',
};

/// The JSON `invoice_detail` returns: 6 PT sessions (EGP 2,400, one doctor)
/// plus an initial assessment (EGP 600). Figures derive from the documents.
Map<String, dynamic> invoiceDetailJson({
  String id = 'invoice-42',
  int number = 42,
  int version = 3,
  List<Map<String, dynamic>> receipts = const [],
  List<Map<String, dynamic>> refunds = const [],
  String? voidedBy,
  Map<String, dynamic>? replacedBy,
  Map<String, dynamic>? replaces,
  String ptService = 'pt6',
}) {
  bool active(Map<String, dynamic> doc) => doc['voided_at'] == null;
  int sum(Iterable<Map<String, dynamic>> docs, String key) =>
      docs.where(active).fold(0, (total, doc) => total + (doc[key] as int));
  final int received = sum(receipts, 'amount_minor');
  final int paidBack = sum(refunds, 'payback_minor');
  final int reduced = sum(refunds, 'value_minor');
  final int laterDiscount = sum(refunds.where((doc) => doc['kind'] == 'discount'), 'value_minor');
  final int refunded = reduced - laterDiscount;
  final int cancelled = refunds.where(active).fold(
      0, (total, doc) => total + ((doc['lines'] as List).first as Map)['sessions_cancelled'] as int);
  const int total = 300000;
  final int value = total - reduced, collected = received - paidBack;
  final int due = voidedBy == null ? value - collected : 0;
  return {
    'id': id, 'branch': 'tagamoa', 'number': number, 'patient_id': 'patient-fixture',
    'patient_name': 'Nour Ahmed Hassan', 'file_number': 107, 'invoice_date': '2026-11-10',
    'subtotal_minor': total, 'discount_kind': 'none', 'discount_value': 0, 'discount_minor': 0,
    'total_minor': total, 'note': null, 'created_at': '2026-11-10T08:30:00Z',
    'created_by_name': 'Nour Mahmoud', 'version': version, ..._void(voidedBy),
    'refunded_minor': refunded, 'later_discount_minor': laterDiscount, 'value_minor': value, 'received_minor': received,
    'paid_back_minor': paidBack, 'net_collected_minor': collected, 'due_minor': due,
    'status': voidedBy != null ? 'voided' : due == 0 ? (refunded > 0 ? 'refunded' : 'paid')
        : collected > 0 ? 'partially_paid' : 'unpaid',
    'services': '6 PT sessions, Initial assessment', 'doctors': ['Dr. Mariam Khaled'],
    'lines': [
      {
        'id': 'line-1', 'service_id': ptService, 'service_name': '6 PT sessions',
        'service_type': 'pt_session', 'quantity': 1, 'unit_price_minor': 240000,
        'gross_minor': 240000, 'net_minor': 240000, 'sessions_granted': 6,
        'value_minor': 240000 - reduced, 'collected_minor': 0, 'sessions_left': 6 - cancelled,
        'doctors': [{'id': 'staff-fixture', 'name': 'Dr. Mariam Khaled'}],
      },
      {
        'id': 'line-2', 'service_id': 'ia', 'service_name': 'Initial assessment',
        'service_type': 'initial_assessment', 'quantity': 1, 'unit_price_minor': 60000,
        'gross_minor': 60000, 'net_minor': 60000, 'sessions_granted': 0,
        'value_minor': 60000, 'collected_minor': 0, 'sessions_left': 0, 'doctors': <Object>[],
      },
    ],
    'receipts': receipts, 'refunds': refunds, 'replaced_by': replacedBy, 'replaces': replaces,
  };
}

InvoiceDetail sampleDetail({
  List<Map<String, dynamic>> receipts = const [],
  List<Map<String, dynamic>> refunds = const [],
  String? voidedBy,
  String ptService = 'pt6',
}) => InvoiceDetail.fromJson(invoiceDetailJson(
  receipts: receipts, refunds: refunds, voidedBy: voidedBy, ptService: ptService,
));

/// Part paid by cash and Visa, with one voided receipt on record.
InvoiceDetail get partPaidDetail => sampleDetail(receipts: [
  receiptJson(31, 100000),
  receiptJson(32, 20000, hour: 10, voidedBy: 'Nour Mahmoud'),
  receiptJson(33, 50000, method: 'visa', hour: 11),
]);

/// Fully paid, then four sessions refunded with EGP 1,600 paid back.
InvoiceDetail get refundedDetail => sampleDetail(
  receipts: [receiptJson(31, 300000)],
  refunds: [refundJson(4, value: 160000, payback: 160000, sessions: 4)],
);
