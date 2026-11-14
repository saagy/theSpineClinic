import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/billing_report.dart';
import '../domain/billing_report_data.dart';

class BillingReportRepositoryImpl implements BillingReportRepository {
  BillingReportRepositoryImpl(this._service);
  final SupabaseService _service;

  @override
  Future<Result<BillingReportData>> report(BillingReportQuery query) async {
    try {
      return Result.success(switch (query.kind) {
        BillingReportKind.money => MoneyReport.fromJson(await _invoice(query, 'money')),
        BillingReportKind.revenue => await _revenue(query),
        BillingReportKind.sessions => DoctorSessionsReport.fromJson(
          await _service.rpc<Map<String, dynamic>>(
            'doctor_session_report',
            params: query.toParams(),
          ),
          forDoctor: query.doctorId != null,
        ),
        BillingReportKind.services => ServicesReport.fromJson(await _invoice(query, 'services')),
        BillingReportKind.outstanding => OutstandingReport.fromJson(
          await _invoice(query, 'outstanding'),
        ),
      });
    } catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  Future<Map<String, dynamic>> _invoice(BillingReportQuery query, String kind) => _service
      .rpc<Map<String, dynamic>>('invoice_report', params: query.toParams(invoiceKind: kind));

  /// One doctor's share, or every line with the split between doctors. The
  /// two reads for all doctors run together over the same period.
  Future<RevenueReport> _revenue(BillingReportQuery query) async {
    if (query.doctorId != null) return RevenueReport.fromJson(await _invoice(query, 'doctor'));
    final List<Map<String, dynamic>> both = await Future.wait([
      _invoice(query, 'revenue'),
      _invoice(query, 'doctors'),
    ]);
    return RevenueReport.fromJson(both[0], byDoctor: DoctorTotals.fromJson(both[1]));
  }
}
