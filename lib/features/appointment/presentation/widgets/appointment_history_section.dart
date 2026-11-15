/// A visit's history on the appointment detail screen: who booked it, every
/// check-in, undo, cancellation and no-show, when, and any reason given.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_event.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/shared/widgets/eyebrow_label.dart';

const _t = AppStrings.visit;

/// What an event did, in the words staff use.
String appointmentEventLabel(AppointmentEvent event) => switch (event.kind) {
  AppointmentEventKind.booked => _t.eventBooked,
  AppointmentEventKind.deleted => _t.eventDeleted,
  AppointmentEventKind.status => switch ((event.fromStatus, event.toStatus)) {
    (_, AppointmentStatus.checkedIn) => _t.eventCheckedIn,
    (_, AppointmentStatus.cancelled) => _t.eventCancelled,
    (_, AppointmentStatus.noShow) => _t.eventNoShow,
    (AppointmentStatus.checkedIn, AppointmentStatus.scheduled) => _t.eventCheckInUndone,
    (AppointmentStatus.cancelled, AppointmentStatus.scheduled) => _t.eventRestored,
    (AppointmentStatus.noShow, AppointmentStatus.scheduled) => _t.eventNoShowUndone,
    _ => _t.eventChanged,
  },
};

class AppointmentHistorySection extends ConsumerWidget {
  const AppointmentHistorySection({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle muted = AppTextStyles.bodySecondary.copyWith(color: colors.onSurfaceVariant);
    final events = ref.watch(appointmentEventsProvider(appointmentId));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(color: colors.outlineVariant, width: 0.5),
        boxShadow: [ClinicColors.of(context).cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EyebrowLabel(text: _t.history, isUppercase: false),
          const SizedBox(height: AppSizes.p8),
          events.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.p8),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => Text(_t.historyError, style: muted),
            data: (list) => list.isEmpty
                ? Text(_t.historyEmpty, style: muted)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Newest first: the latest change is what staff look for.
                      for (final event in list.reversed) _EventRow(event: event),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});
  final AppointmentEvent event;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    final String? reason = event.reason;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointmentEventLabel(event),
            style: AppTextStyles.bodyMedium.copyWith(color: colors.onSurface),
          ),
          Text(
            _t.eventBy(event.actorName ?? _t.unknownStaff, Formatters.formatDateTime(event.at)),
            style: muted,
          ),
          if (reason != null) Text(_t.eventReason(reason), style: muted),
        ],
      ),
    );
  }
}
