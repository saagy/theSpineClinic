/// Domain-layer contract for payment data operations.
///
/// Implementations live in `lib/features/payments/data/`.
/// Rule 4 — every method returns `Result<T>`, never a raw future.
library;

import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_settings.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';

/// Defines the payment data operations available to the application.
abstract class PaymentRepository {
  /// Records a new payment in the database.
  Future<Result<void>> recordPayment(PaymentRecord payment);

  /// Fetches all payment records for a specific patient, sorted by recorded_at descending.
  Future<Result<List<PaymentRecord>>> getPaymentsForPatient(String patientId);

  /// Fetches the single-row clinic settings to resolve configured packages.
  Future<Result<ClinicSettings>> getClinicSettings();

  /// Fetches the configured clinic packages directly.
  Future<Result<List<ClinicPackage>>> getClinicPackages();

  /// Updates the configured clinic packages list inside clinic_settings.
  Future<Result<void>> updateClinicPackages(List<ClinicPackage> packages, String updatedBy);
}
