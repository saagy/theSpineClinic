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
      final Map<String, dynamic> json = await _service.rpc<Map<String, dynamic>>(
        'invoice_report',
        params: query.toParams(),
      );
      return Result.success(switch (query.kind) {
        BillingReportKind.money => MoneyReport.fromJson(json),
        BillingReportKind.revenue => RevenueReport.fromJson(json, forDoctor: false),
        BillingReportKind.doctor => RevenueReport.fromJson(json, forDoctor: true),
        BillingReportKind.doctors => DoctorsReport.fromJson(json),
        BillingReportKind.outstanding => OutstandingReport.fromJson(json),
        BillingReportKind.services => ServicesReport.fromJson(json),
      });
    } catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}
