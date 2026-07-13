import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';

enum BookingWorkboardView { due, schedule }

class BookingWorkboardState {
  const BookingWorkboardState({
    required this.date,
    this.doctorId,
    this.view = BookingWorkboardView.due,
    this.duePatients = const [],
    this.schedule = const [],
    this.dueLoading = false,
    this.scheduleLoading = false,
    this.dueError,
    this.scheduleError,
  });

  final DateTime date;
  final String? doctorId;
  final BookingWorkboardView view;
  final List<Patient> duePatients;
  final List<AppointmentWithPatient> schedule;
  final bool dueLoading;
  final bool scheduleLoading;
  final Object? dueError;
  final Object? scheduleError;

  BookingWorkboardState copyWith({
    DateTime? date,
    String? doctorId,
    bool clearDoctor = false,
    BookingWorkboardView? view,
    List<Patient>? duePatients,
    List<AppointmentWithPatient>? schedule,
    bool? dueLoading,
    bool? scheduleLoading,
    Object? dueError,
    Object? scheduleError,
    bool clearDueError = false,
    bool clearScheduleError = false,
  }) {
    return BookingWorkboardState(
      date: date ?? this.date,
      doctorId: clearDoctor ? null : (doctorId ?? this.doctorId),
      view: view ?? this.view,
      duePatients: duePatients ?? this.duePatients,
      schedule: schedule ?? this.schedule,
      dueLoading: dueLoading ?? this.dueLoading,
      scheduleLoading: scheduleLoading ?? this.scheduleLoading,
      dueError: clearDueError ? null : (dueError ?? this.dueError),
      scheduleError: clearScheduleError
          ? null
          : (scheduleError ?? this.scheduleError),
    );
  }
}
