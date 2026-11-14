import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/patient_visit_clash.dart';
import 'package:spine_clinic_app/features/appointment/presentation/patient_visit_clash_provider.dart';
import 'booking_warning_panel.dart';

const _s = AppStrings.bookingClash;

/// How many clashing dates a recurring series lists before "and N more".
const int _maxListed = 3;

/// Warns, without blocking, when the patient already has a visit on a day
/// being booked. Stays silent while loading or if the check fails: it is
/// advice, and the booking itself is still validated by the database.
class PatientVisitClashWarning extends ConsumerWidget {
  const PatientVisitClashWarning({
    super.key,
    required this.patientId,
    required this.starts,
    this.ignoreAppointmentId,
  });

  final String patientId;

  /// Local start times of the visits being booked.
  final List<DateTime> starts;

  /// The appointment being edited, which must not clash with itself.
  final String? ignoreAppointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (starts.isEmpty) return const SizedBox.shrink();
    final DateTime first = starts.reduce((a, b) => a.isBefore(b) ? a : b);
    final List<Appointment> visits = ref
            .watch(patientVisitsFromProvider((
              patientId: patientId,
              from: DateTime(first.year, first.month, first.day),
            )))
            .value ??
        const [];
    final List<PatientVisitClash> clashes = findPatientVisitClashes(
      requested: starts,
      existing: visits,
      ignoreId: ignoreAppointmentId,
    );
    if (clashes.isEmpty) return const SizedBox.shrink();

    final String title = starts.length > 1
        ? _s.severalDates(clashes.length)
        : (clashes.single.sameTime ? _s.sameTime : _s.sameDay);
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p12),
      child: BookingWarningPanel(
        icon: Icons.event_busy_outlined,
        title: title,
        lines: [
          for (final PatientVisitClash clash in clashes.take(_maxListed)) _line(context, clash),
          if (clashes.length > _maxListed) _s.more(clashes.length - _maxListed),
        ],
        note: _s.note,
      ),
    );
  }

  String _line(BuildContext context, PatientVisitClash clash) {
    final Appointment visit = clash.existing;
    final DateTime at = visit.scheduledAt.toLocal();
    final String line = _s.visitLine(
      DateFormat.MMMEd().format(at),
      MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(at)),
      visit.type.displayLabel,
      visit.branch?.displayLabel,
    );
    return clash.sameTime ? _s.sameTimeTag(line) : line;
  }
}
