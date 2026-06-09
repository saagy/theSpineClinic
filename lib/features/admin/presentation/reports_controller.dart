import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/features/admin/data/admin_repository.dart';
import 'package:spine_clinic_app/features/admin/presentation/admin_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

part 'reports_controller.g.dart';

/// Available date range presets.
enum DateFrame {
  /// Today's metrics.
  today,

  /// Current calendar week (Monday-Sunday).
  thisWeek,

  /// Current calendar month.
  thisMonth,

  /// Custom date range selection.
  custom,
}

/// Filter criteria for reports analytics.
class ReportsFilter {
  /// Creates a [ReportsFilter] instance.
  const ReportsFilter({
    this.clinic,
    required this.dateFrame,
    this.customStartDate,
    this.customEndDate,
  });

  /// The filtered clinic location (null represents All).
  final ClinicLocation? clinic;

  /// The filtered date range preset.
  final DateFrame dateFrame;

  /// Start date for custom range filter.
  final DateTime? customStartDate;

  /// End date for custom range filter.
  final DateTime? customEndDate;

  /// Copy constructor.
  ReportsFilter copyWith({
    ClinicLocation? Function()? clinic,
    DateFrame? dateFrame,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return ReportsFilter(
      clinic: clinic != null ? clinic() : this.clinic,
      dateFrame: dateFrame ?? this.dateFrame,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

/// Provider managing active report query filters.
@riverpod
class ReportsFilterState extends _$ReportsFilterState {
  @override
  ReportsFilter build() {
    return const ReportsFilter(
      clinic: null,
      dateFrame: DateFrame.thisMonth,
    );
  }

  /// Changes the filtered clinic.
  void setClinic(ClinicLocation? clinic) {
    state = state.copyWith(clinic: () => clinic);
  }

  /// Sets the date preset or custom range bounds.
  void setDateFrame(DateFrame dateFrame, {DateTime? start, DateTime? end}) {
    state = state.copyWith(
      dateFrame: dateFrame,
      customStartDate: start,
      customEndDate: end,
    );
  }
}

/// Async provider fetching report analytics metrics from Supabase.
/// Depends on [reportsFilterStateProvider] to reactively query.
@riverpod
Future<ReportData> reportsData(Ref ref) async {
  final filter = ref.watch(reportsFilterStateProvider);
  final repo = ref.read(adminRepositoryProvider);

  final now = DateTime.now();
  DateTime startDate;
  DateTime endDate;

  switch (filter.dateFrame) {
    case DateFrame.today:
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      break;
    case DateFrame.thisWeek:
      final weekday = now.weekday;
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
      endDate = startDate.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));
      break;
    case DateFrame.thisMonth:
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1));
      break;
    case DateFrame.custom:
      startDate = filter.customStartDate ?? DateTime(now.year, now.month, now.day);
      endDate = filter.customEndDate ?? DateTime(now.year, now.month, now.day).add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      break;
  }

  final result = await repo.getReportData(
    clinic: filter.clinic,
    startDate: startDate,
    endDate: endDate,
  );

  return result.when(
    success: (data) => data,
    failure: (error) => throw error,
  );
}
