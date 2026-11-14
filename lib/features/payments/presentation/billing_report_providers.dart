import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/supabase_service.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../patient/domain/clinic_location.dart';
import '../data/billing_report_repository_impl.dart';
import '../domain/billing_report.dart';
import '../domain/billing_report_data.dart';
import '../domain/invoice_access.dart';
import 'billing_report_view.dart';
import 'billing_report_views.dart';

part 'billing_report_providers.g.dart';

@Riverpod(keepAlive: true)
BillingReportRepository billingReportRepository(Ref ref) =>
    BillingReportRepositoryImpl(SupabaseService.instance);

/// The Billing tab's selected report and its shared filters.
class BillingReportFilter {
  const BillingReportFilter({
    this.kind = BillingReportKind.money,
    this.period = ReportPeriod.today,
    this.custom,
    this.branch,
    this.doctorId,
    this.doctorName,
  });
  final BillingReportKind kind;
  final ReportPeriod period;
  final ReportRange? custom;
  final ClinicLocation? branch;
  final String? doctorId;
  final String? doctorName;

  BillingReportFilter copyWith({
    BillingReportKind? kind,
    ReportPeriod? period,
    ReportRange? custom,
    ClinicLocation? Function()? branch,
    String? Function()? doctorId,
    String? Function()? doctorName,
  }) => BillingReportFilter(
    kind: kind ?? this.kind,
    period: period ?? this.period,
    custom: custom ?? this.custom,
    branch: branch == null ? this.branch : branch(),
    doctorId: doctorId == null ? this.doctorId : doctorId(),
    doctorName: doctorName == null ? this.doctorName : doctorName(),
  );

  ReportRange range(DateTime now) => ReportRange.of(period, now, custom: custom);

  BillingReportQuery query(DateTime now) => BillingReportQuery(
    kind: kind,
    range: range(now),
    branch: branch,
    doctorId: kind.usesDoctor ? doctorId : null,
  );
}

/// Kept while the app is open, so coming back to Billing shows the same
/// report and filters. A new sign-in starts over from today's money.
@Riverpod(keepAlive: true)
class BillingReportFilterController extends _$BillingReportFilterController {
  @override
  BillingReportFilter build() {
    // Only a different person or branch starts over; profile reloads keep
    // the current choices.
    final (_, ClinicLocation? branch) = ref.watch(
      currentUserProvider.select((user) => (user.value?.id, InvoiceAccess.fixedBranch(user.value))),
    );
    return BillingReportFilter(branch: branch);
  }

  void setKind(BillingReportKind kind) => state = state.copyWith(kind: kind);

  void setPeriod(ReportPeriod period) => state = state.copyWith(period: period);

  void setCustomRange(ReportRange range) =>
      state = state.copyWith(period: ReportPeriod.custom, custom: range);

  void setBranch(ClinicLocation? branch) => state = state.copyWith(branch: () => branch);

  void setDoctor(String? id, String? name) =>
      state = state.copyWith(doctorId: () => id, doctorName: () => name);
}

/// A failed report shows its error and a Retry button straight away.
Duration? _noRetry(int retryCount, Object error) => null;

/// One report. The database checks the same permission on every request.
@Riverpod(retry: _noRetry)
Future<BillingReportData> billingReport(Ref ref, BillingReportQuery query) async {
  if (!InvoiceAccess.canManage(ref.watch(currentUserProvider).value)) {
    throw const AuthException(
      code: 'invoice/denied',
      message: 'Permission denied',
      userMessageKey: 'invoice_denied',
    );
  }
  return (await ref.watch(billingReportRepositoryProvider).report(query)).when(
    success: (report) => report,
    failure: (error) => throw error,
  );
}

/// The report laid out for the screen and print. Kept per request so table
/// paging survives rebuilds.
@Riverpod(retry: _noRetry)
Future<ReportView> billingReportView(Ref ref, BillingReportQuery query) async => buildReportView(
  await ref.watch(billingReportProvider(query).future),
  singleDay: query.isSingleDay,
);
