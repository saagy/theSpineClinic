import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_settings.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_repository.dart';

/// Supabase-backed implementation of [PaymentRepository].
class PaymentRepositoryImpl implements PaymentRepository {
  /// Creates a [PaymentRepositoryImpl] instance with the required [supabaseService].
  PaymentRepositoryImpl({required SupabaseService supabaseService})
      : _service = supabaseService;

  final SupabaseService _service;

  static const String _paymentRecordsTable = 'payment_records';
  static const String _clinicSettingsTable = 'clinic_settings';

  @override
  Future<Result<void>> recordPayment(PaymentRecord payment) async {
    try {
      final Map<String, dynamic> paymentJson = payment.toJson();
      if (payment.id.isEmpty) {
        paymentJson.remove('id');
      }
      if (payment.recordedBy == null) {
        paymentJson.remove('recorded_by');
      }
      await _service.guardQuery(
        () => _service.from(_paymentRecordsTable).insert(paymentJson),
      );
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<List<PaymentRecord>>> getPaymentsForPatient(String patientId) async {
    try {
      final List<Map<String, dynamic>> rows = await _service.guardQuery(
        () => _service
            .from(_paymentRecordsTable)
            .select()
            .eq('patient_id', patientId)
            .order('recorded_at', ascending: false),
      );
      return Result.success(rows.map(PaymentRecord.fromJson).toList());
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<ClinicSettings>> getClinicSettings() async {
    try {
      final Map<String, dynamic> row = await _service.guardQuery(
        () => _service.from(_clinicSettingsTable).select().limit(1).single(),
      );
      return Result.success(ClinicSettings.fromJson(row));
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<List<ClinicPackage>>> getClinicPackages() async {
    final result = await getClinicSettings();
    return result.when(
      success: (settings) => Result.success(settings.packages),
      failure: (error) => Result.failure(error),
    );
  }
}
