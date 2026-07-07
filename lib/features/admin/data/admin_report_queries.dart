import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/admin/data/admin_report_models.dart';
import 'package:spine_clinic_app/features/admin/data/admin_report_sources.dart';
import 'package:spine_clinic_app/features/admin/data/admin_trend_queries.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

Future<Result<ReportData>> fetchReportData(
  SupabaseService service, {
  required ClinicLocation? clinic,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    final patients = await reportPatients(service, clinic);
    final payments = await reportPayments(service, clinic, startDate, endDate);
    final appointments = await reportAppointments(
      service,
      clinic,
      startDate,
      endDate,
    );
    final doctorNames = await reportDoctorNames(service);

    final patientMetrics = _patientMetrics(patients, startDate, endDate);
    final revenueMetrics = _revenueMetrics(payments);
    final appointmentMetrics = _appointmentMetrics(appointments, doctorNames);

    return Result.success(
      ReportData(
        totalPatients: patients.length,
        newPatients: patientMetrics.newPatients,
        totalAppointments: appointments.length,
        grossIncome: revenueMetrics.grossIncome,
        totalPackageBalances: patientMetrics.totalPackageBalances,
        statusBreakdown: appointmentMetrics.statusBreakdown,
        typeBreakdown: appointmentMetrics.typeBreakdown,
        doctorBreakdown: appointmentMetrics.doctorBreakdown,
        tagamoaMetrics: BranchMetrics(
          totalPatients: patientMetrics.tagamoaPatients,
          totalAppointments: appointmentMetrics.tagamoaAppointments,
          grossIncome: revenueMetrics.tagamoaIncome,
        ),
        masrElgedidaMetrics: BranchMetrics(
          totalPatients: patientMetrics.masrElgedidaPatients,
          totalAppointments: appointmentMetrics.masrElgedidaAppointments,
          grossIncome: revenueMetrics.masrElgedidaIncome,
        ),
        monthlyTrends: await reportMonthlyTrends(service, clinic),
        yearlyTrends: await reportYearlyTrends(service, clinic),
      ),
    );
  } on AppException catch (e) {
    return Result.failure(e);
  } on Exception catch (e) {
    return Result.failure(AppException.fromSupabaseException(e));
  }
}

_PatientMetrics _patientMetrics(
  List<Map<String, dynamic>> rows,
  DateTime start,
  DateTime end,
) {
  var tagamoa = 0;
  var masr = 0;
  var newPatients = 0;
  var balances = 0;
  for (final row in rows) {
    final clinic = row['clinic'] as String? ?? '';
    if (clinic == ClinicLocation.tagamoa.dbValue) tagamoa++;
    if (clinic == ClinicLocation.masrElgedida.dbValue) masr++;
    balances +=
        ((row['session_balance'] as int?) ?? 0) +
        ((row['traction_balance'] as int?) ?? 0);
    final created = row['created_at'] as String?;
    if (created == null) continue;
    final date = DateTime.parse(created);
    if (date.isAfter(start) && date.isBefore(end)) newPatients++;
  }
  return (
    newPatients: newPatients,
    totalPackageBalances: balances,
    tagamoaPatients: tagamoa,
    masrElgedidaPatients: masr,
  );
}

_RevenueMetrics _revenueMetrics(List<Map<String, dynamic>> rows) {
  var gross = 0.0;
  var tagamoa = 0.0;
  var masr = 0.0;
  for (final row in rows) {
    final amount = (row['amount'] as num?)?.toDouble() ?? 0;
    gross += amount;
    final patient = row['patient'];
    final clinic = patient is Map<String, dynamic>
        ? patient['clinic'] as String? ?? ''
        : '';
    if (clinic == ClinicLocation.tagamoa.dbValue) tagamoa += amount;
    if (clinic == ClinicLocation.masrElgedida.dbValue) masr += amount;
  }
  return (grossIncome: gross, tagamoaIncome: tagamoa, masrElgedidaIncome: masr);
}

_AppointmentMetrics _appointmentMetrics(
  List<Map<String, dynamic>> rows,
  Map<String, String> doctorNames,
) {
  final statusBreakdown = <String, int>{};
  final typeBreakdown = <String, int>{};
  final doctorBreakdown = <String, int>{};
  var tagamoa = 0;
  var masr = 0;
  for (final row in rows) {
    _increment(statusBreakdown, row['status'] as String? ?? 'unknown');
    _increment(typeBreakdown, row['type'] as String? ?? 'unknown');
    final patient = row['patient'];
    final clinic = patient is Map<String, dynamic>
        ? patient['clinic'] as String? ?? ''
        : '';
    if (clinic == ClinicLocation.tagamoa.dbValue) {
      tagamoa++;
    }
    if (clinic == ClinicLocation.masrElgedida.dbValue) {
      masr++;
    }
    final doctors = row['appointment_doctors'] as List<Object?>? ?? const [];
    for (final item in doctors.whereType<Map<String, dynamic>>()) {
      if (item['is_active'] != true) continue;
      final id = item['doctor_id'] as String?;
      if (id != null) {
        _increment(doctorBreakdown, doctorNames[id] ?? 'Unknown Doctor');
      }
    }
  }
  return (
    statusBreakdown: statusBreakdown,
    typeBreakdown: typeBreakdown,
    doctorBreakdown: doctorBreakdown,
    tagamoaAppointments: tagamoa,
    masrElgedidaAppointments: masr,
  );
}

void _increment(Map<String, int> map, String key) {
  map[key] = (map[key] ?? 0) + 1;
}

typedef _PatientMetrics = ({
  int newPatients,
  int totalPackageBalances,
  int tagamoaPatients,
  int masrElgedidaPatients,
});

typedef _RevenueMetrics = ({
  double grossIncome,
  double tagamoaIncome,
  double masrElgedidaIncome,
});

typedef _AppointmentMetrics = ({
  Map<String, int> statusBreakdown,
  Map<String, int> typeBreakdown,
  Map<String, int> doctorBreakdown,
  int tagamoaAppointments,
  int masrElgedidaAppointments,
});
