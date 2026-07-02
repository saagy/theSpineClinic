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

  @override
  Future<Result<void>> updateClinicPackages(List<ClinicPackage> packages, String updatedBy) async {
    try {
      final settingsResult = await getClinicSettings();
      return await settingsResult.when(
        success: (settings) async {
          final packageListJson = packages.map((p) => p.toJson()).toList();
          await _service.guardQuery(() => _service
              .from(_clinicSettingsTable)
              .update({
                'packages': packageListJson,
                'updated_by': updatedBy,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', settings.id));
          return const Result.success(null);
        },
        failure: (error) => Result.failure(error),
      );
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> deletePayment(String paymentId) async {
    try {
      await _service.guardQuery(
        () => _service.from(_paymentRecordsTable).delete().eq('id', paymentId),
      );
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> updatePayment({
    required String paymentId,
    required double amount,
    required String reason,
    double? totalPrice,
  }) async {
    try {
      await _service.guardQuery(
        () => _service.from(_paymentRecordsTable).update({
          'amount': amount,
          'reason': reason,
          'total_price': totalPrice,
        }).eq('id', paymentId),
      );
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }

  @override
  Future<Result<void>> collectDue({
    required String paymentId,
    required double additionalAmount,
  }) async {
    try {
      // First fetch current payment record to get the current amount
      final List<Map<String, dynamic>> rows = await _service.guardQuery(
        () => _service
            .from(_paymentRecordsTable)
            .select('amount')
            .eq('id', paymentId),
      );
      if (rows.isEmpty) {
        return Result.failure(const UnknownException(message: 'Payment record not found'));
      }
      final double currentAmount = (rows.first['amount'] as num).toDouble();

      // Update amount to currentAmount + additionalAmount
      await _service.guardQuery(
        () => _service.from(_paymentRecordsTable).update({
          'amount': currentAmount + additionalAmount,
        }).eq('id', paymentId),
      );
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}
