/// Data-transfer objects for the analytics feature.
///
/// Each DTO corresponds to one of the four independent analytics sections
/// and is produced by [AnalyticsRepository] methods.
library;

/// Aggregated financial metrics for a given time range.
class FinancialSummary {
  const FinancialSummary({
    required this.totalRevenue,
    required this.revenueByPaymentType,
    required this.revenueByBranch,
    required this.outstandingBalanceCount,
    required this.owedSessions,
    required this.owedTractionSessions,
    required this.packageSalesCount,
    required this.packageSalesValue,
  });

  final double totalRevenue;
  final Map<String, double> revenueByPaymentType;
  final Map<String, double> revenueByBranch;
  final int outstandingBalanceCount;
  final int owedSessions;
  final int owedTractionSessions;
  final int packageSalesCount;
  final double packageSalesValue;
}

/// Aggregated appointment metrics for a given time range.
class AppointmentSummary {
  const AppointmentSummary({
    required this.totalAppointments,
    required this.attendanceRate,
    required this.cancellationRate,
    required this.byStatus,
    required this.byDayOfWeek,
  });

  final int totalAppointments;
  final double attendanceRate;
  final double cancellationRate;
  final Map<String, int> byStatus;
  final Map<String, int> byDayOfWeek;
}

class DoctorDailyLog {
  const DoctorDailyLog({
    required this.date,
    required this.checkedInAppointments,
    required this.eligibleAppointments,
  });

  final DateTime date;
  final int checkedInAppointments;
  final int eligibleAppointments;
}

class DoctorPerformance {
  const DoctorPerformance({
    required this.id,
    required this.fullName,
    required this.eligibleAppointments,
    required this.checkedInAppointments,
    required this.activeDays,
    required this.dailyLogs,
  });

  final String id;
  final String fullName;
  final int eligibleAppointments;
  final int checkedInAppointments;
  final int activeDays;
  final List<DoctorDailyLog> dailyLogs;
}

/// Aggregated staff performance metrics for a given time range.
class StaffSummary {
  const StaffSummary({
    required this.appointmentsPerDoctor,
    required this.attendanceRatePerDoctor,
    required this.topDoctors,
    required this.doctorPerformances,
  });

  final Map<String, int> appointmentsPerDoctor;
  final Map<String, double> attendanceRatePerDoctor;
  final List<String> topDoctors;
  final List<DoctorPerformance> doctorPerformances;
}

/// Aggregated patient demographics for a given time range.
class PatientSummary {
  const PatientSummary({
    required this.newRegistrations,
    required this.totalActivePatients,
    required this.patientsByBranch,
    required this.returningRatio,
  });

  final int newRegistrations;
  final int totalActivePatients;
  final Map<String, int> patientsByBranch;
  final double returningRatio;
}
