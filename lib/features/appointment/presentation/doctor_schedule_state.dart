import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/schedule_week.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';

class DoctorScheduleState {
  const DoctorScheduleState({
    this.allItems = const <AppointmentWithPatient>[],
    this.selectedDate,
    this.loading = true,
    this.error,
    this.doctor,
    this.showCancelled = false,
  });

  final List<AppointmentWithPatient> allItems;
  final DateTime? selectedDate;
  final bool loading;
  final Object? error;
  final Staff? doctor;
  final bool showCancelled;

  List<AppointmentWithPatient> get itemsForSelectedDay {
    if (selectedDate == null) return <AppointmentWithPatient>[];
    final DateTime selected = ScheduleWeek.day(selectedDate!);
    Iterable<AppointmentWithPatient> matching = allItems.where(
      (AppointmentWithPatient item) =>
          ScheduleWeek.day(item.appointment.scheduledAt.toLocal()) == selected,
    );
    if (!showCancelled) {
      matching = matching.where(
        (AppointmentWithPatient item) =>
            item.appointment.status != AppointmentStatus.cancelled,
      );
    }
    return matching.toList()..sort(
      (AppointmentWithPatient a, AppointmentWithPatient b) =>
          a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt),
    );
  }

  bool get isToday =>
      selectedDate != null &&
      ScheduleWeek.day(selectedDate!) == ScheduleWeek.day(DateTime.now());

  Map<DateTime, int> get dayAppointmentCounts {
    final Map<DateTime, int> counts = <DateTime, int>{};
    for (final AppointmentWithPatient item in allItems) {
      if (item.appointment.status == AppointmentStatus.cancelled) continue;
      final DateTime date = ScheduleWeek.day(
        item.appointment.scheduledAt.toLocal(),
      );
      counts[date] = (counts[date] ?? 0) + 1;
    }
    return counts;
  }

  DoctorScheduleState copyWith({
    List<AppointmentWithPatient>? allItems,
    DateTime? selectedDate,
    bool? loading,
    Object? error,
    bool clearError = false,
    Staff? doctor,
    bool? showCancelled,
  }) {
    return DoctorScheduleState(
      allItems: allItems ?? this.allItems,
      selectedDate: selectedDate ?? this.selectedDate,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      doctor: doctor ?? this.doctor,
      showCancelled: showCancelled ?? this.showCancelled,
    );
  }
}
