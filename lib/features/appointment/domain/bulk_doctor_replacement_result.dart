class BulkDoctorReplacementResult {
  const BulkDoctorReplacementResult({
    required this.replacedCount,
    required this.remainingCount,
  });

  final int replacedCount;
  final int remainingCount;

  factory BulkDoctorReplacementResult.fromJson(Map<String, dynamic> json) {
    return BulkDoctorReplacementResult(
      replacedCount: json['replaced_count'] as int,
      remainingCount: json['remaining_count'] as int,
    );
  }
}
