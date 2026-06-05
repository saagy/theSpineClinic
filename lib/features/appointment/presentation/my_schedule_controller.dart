import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

part 'my_schedule_controller.g.dart';

/// The two distinct horizons of the doctor's agenda view.
enum MyScheduleHorizon {
  /// The chronological feed for the current day.
  today,

  /// The grouped 7-day calendar timeline.
  week,
}

/// Holds the active view state config and the filtered list of schedule items.
class MyScheduleState {
  final MyScheduleHorizon horizon;
  final List<DoctorScheduleItem> items;

  const MyScheduleState({
    required this.horizon,
    required this.items,
  });
}

/// Manages the doctor's calendar schedule, resolving active doctor context,
/// querying database data, and applying correct horizon filtering.
@riverpod
class MyScheduleController extends _$MyScheduleController {
  @override
  FutureOr<MyScheduleState> build() {
    return _fetchState(MyScheduleHorizon.today);
  }

  Future<MyScheduleState> _fetchState(MyScheduleHorizon horizon) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      throw const AuthException(
        code: 'auth/unauthenticated',
        message: 'No authenticated user found.',
      );
    }

    final repo = ref.read(appointmentRepositoryProvider);
    final result = await repo.getDoctorSchedule(user.id);

    final allItems = result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );

    final DateTime localNow = DateTime.now();
    final DateTime todayStart = DateTime(localNow.year, localNow.month, localNow.day);
    final DateTime todayEnd = todayStart.add(const Duration(days: 1));
    final DateTime weekEnd = todayStart.add(const Duration(days: 7));

    final List<DoctorScheduleItem> filtered;
    if (horizon == MyScheduleHorizon.today) {
      filtered = allItems.where((item) {
        final DateTime localSched = item.appointment.scheduledAt.toLocal();
        return localSched.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            localSched.isBefore(todayEnd);
      }).toList();
    } else {
      filtered = allItems.where((item) {
        final DateTime localSched = item.appointment.scheduledAt.toLocal();
        return localSched.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
            localSched.isBefore(weekEnd);
      }).toList();
    }

    return MyScheduleState(horizon: horizon, items: filtered);
  }

  /// Switches the calendar display horizon.
  Future<void> toggleHorizon(MyScheduleHorizon horizon) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchState(horizon));
  }

  /// Forces a database reload using the current active view horizon.
  Future<void> refresh() async {
    final currentHorizon = state.value?.horizon ?? MyScheduleHorizon.today;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchState(currentHorizon));
  }
}
