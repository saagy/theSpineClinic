import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_repository.dart';

/// Supabase-backed implementation of [PaymentRepository].
class PaymentRepositoryImpl implements PaymentRepository {
  /// Creates a [PaymentRepositoryImpl] instance with the required [supabaseService].
  PaymentRepositoryImpl({required SupabaseService supabaseService})
    : _service = supabaseService;

  final SupabaseService _service;

  static const String _paymentRecordsTable = 'payment_records';

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
  Future<Result<List<PaymentRecord>>> getPaymentsForPatient(
    String patientId,
  ) async {
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
        () => _service
            .from(_paymentRecordsTable)
            .update({
              'amount': amount,
              'reason': reason,
              'total_price': totalPrice,
            })
            .eq('id', paymentId),
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
      await _service.guardQuery(
        () => _service.rpc(
          'collect_payment_due',
          params: {
            'p_payment_id': paymentId,
            'p_additional_amount': additionalAmount,
          },
        ),
      );
      return const Result.success(null);
    } on AppException catch (error) {
      return Result.failure(error);
    } on Exception catch (error) {
      return Result.failure(AppException.fromSupabaseException(error));
    }
  }
}
