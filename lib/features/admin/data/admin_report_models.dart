class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.visits,
    required this.revenue,
  });

  final String label;
  final int visits;
  final double revenue;
}

class BranchMetrics {
  const BranchMetrics({
    required this.totalPatients,
    required this.totalAppointments,
    required this.grossIncome,
  });

  final int totalPatients;
  final int totalAppointments;
  final double grossIncome;
}

class ReportData {
  const ReportData({
    required this.totalPatients,
    required this.newPatients,
    required this.totalAppointments,
    required this.grossIncome,
    required this.totalPackageBalances,
    required this.statusBreakdown,
    required this.typeBreakdown,
    required this.doctorBreakdown,
    required this.tagamoaMetrics,
    required this.masrElgedidaMetrics,
    required this.monthlyTrends,
    required this.yearlyTrends,
  });

  final int totalPatients;
  final int newPatients;
  final int totalAppointments;
  final double grossIncome;
  final int totalPackageBalances;
  final Map<String, int> statusBreakdown;
  final Map<String, int> typeBreakdown;
  final Map<String, int> doctorBreakdown;
  final BranchMetrics tagamoaMetrics;
  final BranchMetrics masrElgedidaMetrics;
  final List<TrendPoint> monthlyTrends;
  final List<TrendPoint> yearlyTrends;
}
