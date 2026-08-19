/// Doctor schedule screen with time-of-day greeting, 7-day week strip,
/// and day appointment list with now-indicator.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_day_list.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_week_strip.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// The doctor's daily schedule view.
class DoctorScheduleScreen extends ConsumerWidget {
  const DoctorScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doctorScheduleProvider);
    final notifier = ref.read(doctorScheduleProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.maxContentWidth,
            ),
            child: _Content(
              state: state,
              onDateSelected: notifier.selectDate,
              onStatusChanged: notifier.refresh,
              onToggleCancelled: notifier.toggleShowCancelled,
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.onDateSelected,
    required this.onStatusChanged,
    required this.onToggleCancelled,
  });
  final DoctorScheduleState state;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onStatusChanged;
  final VoidCallback onToggleCancelled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GreetingHeader(doctor: state.doctor),
        DoctorWeekStrip(
          dayCounts: state.dayAppointmentCounts,
          selectedDate: state.selectedDate,
          showCancelled: state.showCancelled,
          onToggleCancelled: onToggleCancelled,
          onDateSelected: onDateSelected,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: state.loading
                ? const KeyedSubtree(
                    key: ValueKey('doc_schedule_loading'),
                    child: SkeletonTileList(count: 5),
                  )
                : state.error != null
                ? KeyedSubtree(
                    key: const ValueKey('doc_schedule_error'),
                    child: _ErrorView(
                      error: state.error!,
                      onRetry: onStatusChanged,
                    ),
                  )
                : KeyedSubtree(
                    key: ValueKey(
                      'doc_schedule_data_${state.selectedDate}_${state.itemsForSelectedDay.length}_${state.showCancelled}',
                    ),
                    child: DoctorDayList(
                      state: state,
                      onStatusChanged: onStatusChanged,
                      onRefresh: () async => onStatusChanged.call(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.doctor});
  final Staff? doctor;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 18) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p20,
        AppSizes.p16,
        AppSizes.p20,
        AppSizes.p8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: AppTextStyles.headingLarge),
                const SizedBox(height: AppSizes.p2),
                Text(
                  doctor?.fullName ?? '',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppException ex = error is AppException
        ? error as AppException
        : UnknownException(message: '$error');
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: () async => onRetry(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: ErrorView(exception: ex, onRetry: onRetry),
          ),
        ],
      ),
    );
  }
}
