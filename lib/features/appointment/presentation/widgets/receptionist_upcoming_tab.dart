/// Upcoming tab: future appointments grouped by date with count headers.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';

/// The "Upcoming" tab content with date-grouped future appointments.
class ReceptionistUpcomingTab extends StatelessWidget {
  /// Creates a [ReceptionistUpcomingTab].
  const ReceptionistUpcomingTab({
    super.key,
    required this.state,
    this.onStatusChanged,
  });

  final ReceptionistAppointmentsState state;
  final VoidCallback? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    if (state.upcomingLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (state.upcomingError != null) {
      return Center(
        child: Text('${state.upcomingError}',
            style: AppTextStyles.bodySecondary),
      );
    }
    if (state.upcoming.isEmpty) {
      return const Center(child: Text('No upcoming appointments'));
    }

    final grouped = _groupByDate(state.upcoming);

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSizes.p8, bottom: AppSizes.p32),
      itemCount: grouped.length,
      itemBuilder: (_, i) => grouped[i],
    );
  }

  List<Widget> _groupByDate(List<AppointmentWithPatient> items) {
    final List<Widget> result = [];
    String? lastKey;

    for (final item in items) {
      final date = item.appointment.scheduledAt.toLocal();
      final key = DateFormat('yyyy-MM-dd').format(date);
      if (key != lastKey) {
        lastKey = key;
        final formatted = DateFormat('E, MMM d').format(date);
        final int count = items.where((a) {
          final d = a.appointment.scheduledAt.toLocal();
          return DateFormat('yyyy-MM-dd').format(d) == key;
        }).length;
        result.add(Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8),
          child: Text(
            '$formatted · $count appointment${count == 1 ? '' : 's'}',
            style: AppTextStyles.captionBold
                .copyWith(color: AppColors.textSecondary),
          ),
        ));
      }
      result.add(ReceptionistAppointmentCard(
        item: item, onStatusChanged: onStatusChanged,
      ));
    }
    return result;
  }
}
