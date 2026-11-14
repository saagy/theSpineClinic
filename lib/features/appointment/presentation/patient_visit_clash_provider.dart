import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';

part 'patient_visit_clash_provider.g.dart';

/// The patient's uncancelled visits from [args.from] on. Keyed by the first
/// booked day, not the whole series, so typing a session count never queries.
@riverpod
Future<List<Appointment>> patientVisitsFrom(
  Ref ref,
  ({String patientId, DateTime from}) args,
) async {
  final result = await ref
      .read(appointmentRepositoryProvider)
      .getPatientVisitsFrom(args.patientId, args.from);
  return result.when(success: (visits) => visits, failure: (error) => throw error);
}
