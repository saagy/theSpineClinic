/// Riverpod provider for booking patient search with limit.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'booking_patient_search_provider.g.dart';

/// Fetches a bounded list of patients (up to 20) for booking selection,
/// querying the server directly instead of loading the entire patient base.
@riverpod
Future<List<Patient>> bookingPatientSearch(Ref ref, String query) async {
  final repo = ref.watch(patientRepositoryProvider);
  final trimmed = query.trim();

  if (trimmed.isEmpty) {
    final Result<List<Patient>> result = await repo.getAllPatients(limit: 20);
    return result.when(
      success: (data) => data,
      failure: (AppException e) => throw e,
    );
  }

  final Result<List<Patient>> result = await repo.searchPatients(query: trimmed);
  return result.when(
    success: (data) => data,
    failure: (AppException e) => throw e,
  );
}
