import '../../patient/domain/clinic_location.dart';
import 'invoice_draft.dart';
import 'invoice_documents.dart';
import 'invoice_summary.dart';
import 'service_catalog_item.dart';

export 'invoice_documents.dart';

/// One service line with its live figures after refunds and collections.
class InvoiceLineDetail {
  const InvoiceLineDetail({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.type,
    required this.quantity,
    required this.unitPriceMinor,
    required this.grossMinor,
    required this.netMinor,
    required this.sessionsGranted,
    required this.valueMinor,
    required this.collectedMinor,
    required this.sessionsLeft,
    this.doctors = const [],
  });

  factory InvoiceLineDetail.fromJson(Map<String, dynamic> json) => InvoiceLineDetail(
    id: json['id'] as String,
    serviceId: json['service_id'] as String,
    serviceName: json['service_name'] as String,
    type: ServiceType.fromDb(json['service_type'] as String),
    quantity: (json['quantity'] as num).toInt(),
    unitPriceMinor: (json['unit_price_minor'] as num).toInt(),
    grossMinor: (json['gross_minor'] as num).toInt(),
    netMinor: (json['net_minor'] as num).toInt(),
    sessionsGranted: (json['sessions_granted'] as num).toInt(),
    valueMinor: (json['value_minor'] as num).toInt(),
    collectedMinor: (json['collected_minor'] as num).toInt(),
    sessionsLeft: (json['sessions_left'] as num).toInt(),
    doctors: [
      for (final Map<String, dynamic> doctor
          in (json['doctors'] as List<Object?>? ?? const []).cast<Map<String, dynamic>>())
        (id: doctor['id'] as String, name: doctor['name'] as String),
    ],
  );

  final String id;
  final String serviceId;
  final String serviceName;
  final ServiceType type;
  final int quantity;
  final int unitPriceMinor;
  final int grossMinor;

  /// Gross minus this line's share of the invoice discount.
  final int netMinor;
  final int sessionsGranted;

  /// Net minus active refunds and discounts given after issue.
  final int valueMinor;
  final int collectedMinor;

  /// Sessions granted minus sessions cancelled by active refunds.
  final int sessionsLeft;
  final List<({String id, String name})> doctors;

  int get sessionsCancelled => sessionsGranted - sessionsLeft;
  int get refundedMinor => netMinor - valueMinor;
  bool get isRefundable => valueMinor > 0 || sessionsLeft > 0;
}

/// The complete invoice returned by `invoice_detail`.
class InvoiceDetail {
  const InvoiceDetail({
    required this.summary,
    required this.patientName,
    required this.subtotalMinor,
    required this.receivedMinor,
    required this.paidBackMinor,
    this.fileNumber,
    this.discountKind = DiscountKind.none,
    this.discountValue = 0,
    this.note,
    this.voided,
    this.lines = const [],
    this.receipts = const [],
    this.refunds = const [],
    this.replacedBy,
    this.replaces,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) => [
      for (final Object? item in json[key] as List<Object?>? ?? const [])
        parse(item! as Map<String, dynamic>),
    ];
    return InvoiceDetail(
      summary: InvoiceSummary.fromJson(json),
      patientName: json['patient_name'] as String,
      fileNumber: (json['file_number'] as num?)?.toInt(),
      subtotalMinor: (json['subtotal_minor'] as num).toInt(),
      receivedMinor: (json['received_minor'] as num).toInt(),
      paidBackMinor: (json['paid_back_minor'] as num).toInt(),
      discountKind: DiscountKind.values.firstWhere(
        (kind) => kind.name == json['discount_kind'],
        orElse: () => DiscountKind.none,
      ),
      discountValue: (json['discount_value'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      voided: VoidStamp.fromJson(json),
      lines: list('lines', InvoiceLineDetail.fromJson),
      receipts: list('receipts', InvoiceReceipt.fromJson),
      refunds: list('refunds', InvoiceRefund.fromJson),
      replacedBy: InvoiceRef.fromJson(json['replaced_by'] as Map<String, dynamic>?),
      replaces: InvoiceRef.fromJson(json['replaces'] as Map<String, dynamic>?),
    );
  }

  final InvoiceSummary summary;
  final String patientName;
  final int? fileNumber;
  final int subtotalMinor;

  /// Money taken by active receipts, before any payback.
  final int receivedMinor;

  /// Money returned to the patient by active refunds.
  final int paidBackMinor;
  final DiscountKind discountKind;

  /// Basis points for percent discounts, piasters for amounts.
  final int discountValue;
  final String? note;
  final VoidStamp? voided;
  final List<InvoiceLineDetail> lines;

  /// Oldest first, including voided receipts.
  final List<InvoiceReceipt> receipts;

  /// Refunds and later discounts, oldest first, including voided ones.
  final List<InvoiceRefund> refunds;
  final InvoiceRef? replacedBy;
  final InvoiceRef? replaces;

  String get id => summary.id;
  String get patientId => summary.patientId;
  ClinicLocation get branch => summary.branch;
  int get version => summary.version;
  int get valueMinor => summary.valueMinor;
  int get collectedMinor => summary.collectedMinor;
  int get dueMinor => summary.dueMinor;
  bool get isVoided => voided != null;

  Iterable<InvoiceReceipt> get activeReceipts => receipts.where((receipt) => !receipt.isVoided);
  Iterable<InvoiceRefund> get activeRefunds => refunds.where((refund) => !refund.isVoided);

  bool get canRecordPayment => !isVoided && dueMinor > 0;
  bool get canRefund => !isVoided && lines.any((line) => line.isRefundable);

  /// A discount needs something left to discount.
  bool get canDiscount => !isVoided && valueMinor > 0;

  /// An invoice can be voided only while it holds no active money documents.
  bool get canVoid => !isVoided && activeReceipts.isEmpty && activeRefunds.isEmpty;
  bool get canCorrect => !isVoided && activeRefunds.isEmpty;

  /// A paid invoice without refunds can be cancelled together with its
  /// payments in one step (`invoice_void_all`).
  bool get canVoidWithPayments => !isVoided && activeRefunds.isEmpty && activeReceipts.isNotEmpty;

  /// A later active refund or discount locks earlier receipts, refunds and
  /// discounts: its figures were calculated from them, so it has to be
  /// voided first.
  bool lockedByLaterRefund(DateTime recordedAt) =>
      activeRefunds.any((refund) => refund.recordedAt.isAfter(recordedAt));

  InvoiceLineDetail? lineById(String lineId) {
    for (final line in lines) {
      if (line.id == lineId) return line;
    }
    return null;
  }
}
