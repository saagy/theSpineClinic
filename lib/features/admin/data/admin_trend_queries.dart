import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/admin/data/admin_report_models.dart';
import 'package:spine_clinic_app/features/admin/data/admin_report_sources.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

Future<List<TrendPoint>> reportMonthlyTrends(
  SupabaseService service,
  ClinicLocation? clinic,
) async {
  final trends = <TrendPoint>[];
  final now = DateTime.now();
  for (var i = 11; i >= 0; i--) {
    final start = DateTime(now.year, now.month - i, 1);
    final end = DateTime(
      now.year,
      now.month - i + 1,
      1,
    ).subtract(const Duration(microseconds: 1));
    final label = '${start.month}/${start.year.toString().substring(2)}';
    trends.add(await _trendPoint(service, clinic, start, end, label));
  }
  return trends;
}

Future<List<TrendPoint>> reportYearlyTrends(
  SupabaseService service,
  ClinicLocation? clinic,
) async {
  final trends = <TrendPoint>[];
  final now = DateTime.now();
  for (var i = 4; i >= 0; i--) {
    final year = now.year - i;
    final start = DateTime(year, 1, 1);
    final end = DateTime(
      year + 1,
      1,
      1,
    ).subtract(const Duration(microseconds: 1));
    trends.add(await _trendPoint(service, clinic, start, end, year.toString()));
  }
  return trends;
}

Future<TrendPoint> _trendPoint(
  SupabaseService service,
  ClinicLocation? clinic,
  DateTime start,
  DateTime end,
  String label,
) async {
  final appointments = await reportAppointments(service, clinic, start, end);
  final payments = await reportPayments(service, clinic, start, end);
  final revenue = payments.fold<double>(
    0,
    (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0),
  );
  return TrendPoint(
    label: label,
    visits: appointments.length,
    revenue: revenue,
  );
}
