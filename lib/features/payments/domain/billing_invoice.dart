import '../../patient/domain/clinic_location.dart';

typedef BillingRow = Map<String, dynamic>;

List<BillingRow> billingRows(Object? value) =>
    (value as List<Object?>? ?? const []).cast<BillingRow>();

enum BillingAction {
  item,
  draft,
  issue,
  receipt,
  credit,
  refund;

  String get wire => this == credit ? 'return' : name;
}

enum BillingMethod { cash, visa }

enum BillingItemKind { service, package }

enum BillingDocumentKind {
  invoice,
  receipt,
  credit,
  refund;

  static BillingDocumentKind fromWire(String value) =>
      value == 'return' ? credit : values.byName(value);
}

class BillingParty {
  const BillingParty(
    this.id,
    this.name, {
    this.fileNumber,
    this.branch,
    this.isSenior = false,
  });
  factory BillingParty.fromJson(BillingRow row) => BillingParty(
    row['id'] as String,
    row['name'] as String,
    fileNumber: row['file_number'] as int?,
    branch: parseBillingBranch(row['branch'] as String?),
    isSenior: row['is_senior'] as bool? ?? false,
  );
  final String id;
  final String name;
  final int? fileNumber;
  final ClinicLocation? branch;
  final bool isSenior;
}

ClinicLocation? parseBillingBranch(String? value) => value == null
    ? null
    : ClinicLocation.values.firstWhere((branch) => branch.dbValue == value);

class BillingItem {
  const BillingItem({
    required this.id,
    required this.name,
    required this.price,
    required this.active,
    required this.version,
    this.kind = BillingItemKind.service,
    this.coveredServiceId,
    this.sessionCount,
    this.validityDays,
    this.insuranceEligible = false,
  });
  factory BillingItem.fromJson(BillingRow row) => BillingItem(
    id: row['id'] as String,
    name: row['name'] as String,
    price: row['price_minor'] as int,
    active: row['active'] as bool,
    version: row['version'] as int,
    kind: BillingItemKind.values.byName(row['kind'] as String),
    coveredServiceId: row['covered_service_id'] as String?,
    sessionCount: row['session_count'] as int?,
    validityDays: row['validity_days'] as int?,
    insuranceEligible: row['insurance_eligible'] as bool,
  );
  final String id;
  final String name;
  final int price;
  final bool active;
  final int version;
  final BillingItemKind kind;
  final String? coveredServiceId;
  final int? sessionCount, validityDays;
  final bool insuranceEligible;
}

class BillingLine {
  BillingLine.fromJson(BillingRow row)
    : id = row['id'] as String,
      itemId = row['item_id'] as String,
      name = row['item_name'] as String,
      quantity = row['quantity'] as int,
      unitPrice = row['price_minor'] as int,
      net = row['net_minor'] as int;
  final String id, itemId, name;
  final int quantity, unitPrice, net;
}

class BillingAllocation {
  BillingAllocation.fromJson(BillingRow row)
    : lineId = row['line_id'] as String,
      amount = row['amount_minor'] as int,
      quantity = row['quantity'] as int?;
  final String lineId;
  final int amount;
  final int? quantity;
}

class BillingMovement {
  BillingMovement.fromJson(BillingRow row)
    : id = row['id'] as String,
      number = row['number'] as int,
      kind = BillingDocumentKind.fromWire(row['kind'] as String),
      amount = row['amount_minor'] as int,
      debtReduced = row['debt_reduced_minor'] as int,
      method = row['method'] == null
          ? null
          : BillingMethod.values.byName(row['method'] as String),
      reason = row['reason'] as String?,
      actor = row['actor_name'] as String,
      recordedAt = DateTime.parse(row['recorded_at'] as String),
      allocations = billingRows(
        row['allocations'],
      ).map(BillingAllocation.fromJson).toList();
  final String id, actor;
  final int number, amount, debtReduced;
  final BillingDocumentKind kind;
  final BillingMethod? method;
  final String? reason;
  final DateTime recordedAt;
  final List<BillingAllocation> allocations;
}

class BillingInvoice {
  BillingInvoice.fromJson(BillingRow row)
    : id = row['id'] as String,
      number = row['number'] as int?,
      patient = BillingParty(
        row['patient_id'] as String,
        row['patient_name'] as String,
        fileNumber: row['file_number'] as int,
      ),
      doctor = BillingParty(
        row['doctor_id'] as String,
        row['doctor_name'] as String,
      ),
      consultant = row['consultant_id'] == null
          ? null
          : BillingParty(
              row['consultant_id'] as String,
              row['consultant_name'] as String,
            ),
      branch = parseBillingBranch(row['branch'] as String)!,
      serviceDate = DateTime.parse(row['service_date'] as String),
      issuedAt = DateTime.tryParse(row['issued_at'] as String? ?? ''),
      version = row['version'] as int,
      discountBps = row['discount_bps'] as int,
      total = row['total_minor'] as int,
      collected = row['collected_minor'] as int,
      credited = row['credited_minor'] as int,
      refunded = row['refunded_minor'] as int,
      outstanding = row['outstanding_minor'] as int,
      refundable = row['refundable_minor'] as int,
      lines = billingRows(row['lines']).map(BillingLine.fromJson).toList(),
      movements = billingRows(
        row['movements'],
      ).map(BillingMovement.fromJson).toList();

  final String id;
  final int? number;
  final BillingParty patient, doctor;
  final BillingParty? consultant;
  final ClinicLocation branch;
  final DateTime serviceDate;
  final DateTime? issuedAt;
  final int version,
      discountBps,
      total,
      collected,
      credited,
      refunded,
      outstanding,
      refundable;
  final List<BillingLine> lines;
  final List<BillingMovement> movements;

  bool get isDraft => number == null;
  int remainingQuantity(BillingLine line) => movements
      .where((movement) => movement.kind == BillingDocumentKind.credit)
      .expand((movement) => movement.allocations)
      .where((allocation) => allocation.lineId == line.id)
      .fold(
        line.quantity,
        (remaining, allocation) => remaining - (allocation.quantity ?? 0),
      );
}
