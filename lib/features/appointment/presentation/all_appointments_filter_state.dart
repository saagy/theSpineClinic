import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable snapshot of all filter parameters captured at reload time
/// so in-flight queries cannot be corrupted by a subsequent filter change.
class FilterSnapshot {
  const FilterSnapshot({
    required this.dateFrom,
    required this.dateTo,
    required this.doctorId,
    required this.clinic,
    required this.status,
    required this.type,
    required this.patientQuery,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? doctorId;
  final String? clinic;
  final String? status;
  final String? type;
  final String patientQuery;
}

/// Notifier tracking whether a load-more fetch is in flight.
class IsLoadingMoreNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

/// Whether a load-more fetch is in flight — watched by the UI to show a
/// bottom-of-list spinner on mobile.
final isLoadingMoreProvider = NotifierProvider<IsLoadingMoreNotifier, bool>(
  IsLoadingMoreNotifier.new,
);
