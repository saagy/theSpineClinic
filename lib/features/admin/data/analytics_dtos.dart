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
    required this.completionRate,
    required this.cancellationRate,
    required this.byStatus,
    required this.byDayOfWeek,
  });

  final int totalAppointments;
  final double completionRate;
  final double cancellationRate;
  final Map<String, int> byStatus;
  final Map<String, int> byDayOfWeek;
}

class DoctorDailyLog {
  const DoctorDailyLog({
    required this.date,
    required this.completedAppointments,
    required this.totalAppointments,
    required this.isAbsent,
    this.coveringDoctorName,
  });

  final DateTime date;
  final int completedAppointments;
  final int totalAppointments;
  final bool isAbsent;
  final String? coveringDoctorName;
}

class DoctorPerformance {
  const DoctorPerformance({
    required this.id,
    required this.fullName,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.absenceCount,
    required this.activeDays,
    required this.dailyLogs,
  });

  final String id;
  final String fullName;
  final int totalAppointments;
  final int completedAppointments;
  final int absenceCount;
  final int activeDays;
  final List<DoctorDailyLog> dailyLogs;
}

/// Aggregated staff performance metrics for a given time range.
class StaffSummary {
  const StaffSummary({
    required this.appointmentsPerDoctor,
    required this.completionRatePerDoctor,
    required this.topDoctors,
    required this.doctorPerformances,
  });

  final Map<String, int> appointmentsPerDoctor;
  final Map<String, double> completionRatePerDoctor;
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
