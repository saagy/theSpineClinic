/// Doctor schedule screen with time-of-day greeting, 7-day week strip,
/// and day appointment list with now-indicator.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_day_list.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_week_strip.dart';

/// The doctor's daily schedule view.
class DoctorScheduleScreen extends ConsumerWidget {
  const DoctorScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doctorScheduleProvider);
    final notifier = ref.read(doctorScheduleProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: state.loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : state.error != null
                ? _ErrorView(error: state.error!, onRetry: notifier.refresh)
                : _Content(
                    state: state,
                    onDateSelected: notifier.selectDate,
                    onStatusChanged: notifier.refresh,
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
  });
  final DoctorScheduleState state;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GreetingHeader(doctor: state.doctor),
        DoctorWeekStrip(
          dayCounts: state.dayAppointmentCounts,
          selectedDate: state.selectedDate,
          onDateSelected: onDateSelected,
        ),
        Expanded(
          child: DoctorDayList(
            state: state,
            onStatusChanged: onStatusChanged,
            onRefresh: () async => onStatusChanged.call(),
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
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting, style: AppTextStyles.headingLarge),
                const SizedBox(height: AppSizes.p2),
                Text(doctor?.fullName ?? '',
                    style: AppTextStyles.headingMedium
                        .copyWith(color: AppColors.textSecondary)),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$error', style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSizes.p16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
