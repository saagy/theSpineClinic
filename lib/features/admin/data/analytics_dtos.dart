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
    required this.outstandingBalanceTotal,
    required this.packageSalesCount,
    required this.packageSalesValue,
  });

  final double totalRevenue;
  final Map<String, double> revenueByPaymentType;
  final Map<String, double> revenueByBranch;
  final int outstandingBalanceCount;
  final double outstandingBalanceTotal;
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

/// Aggregated staff performance metrics for a given time range.
class StaffSummary {
  const StaffSummary({
    required this.appointmentsPerDoctor,
    required this.completionRatePerDoctor,
    required this.topDoctors,
    required this.newStaffInPeriod,
  });

  final Map<String, int> appointmentsPerDoctor;
  final Map<String, double> completionRatePerDoctor;
  final List<String> topDoctors;
  final int newStaffInPeriod;
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
