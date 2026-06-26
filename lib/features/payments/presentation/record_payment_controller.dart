import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/payments/data/payment_repository_impl.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_record.dart';
import 'package:spine_clinic_app/features/payments/domain/payment_repository.dart';

part 'record_payment_controller.g.dart';

/// Provider for the [PaymentRepository] instance.
@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(Ref ref) {
  return PaymentRepositoryImpl(
    supabaseService: SupabaseService.instance,
  );
}

/// Provider fetching available clinic packages.
@riverpod
Future<List<ClinicPackage>> clinicPackages(Ref ref) async {
  final PaymentRepository repo = ref.watch(paymentRepositoryProvider);
  final Result<List<ClinicPackage>> result = await repo.getClinicPackages();
  return result.when(
    success: (packages) => packages,
    failure: (AppException exception) => throw exception,
  );
}

/// Provider fetching payment records for a patient.
@riverpod
Future<List<PaymentRecord>> patientPayments(Ref ref, String patientId) async {
  final PaymentRepository repo = ref.watch(paymentRepositoryProvider);
  final Result<List<PaymentRecord>> result = await repo.getPaymentsForPatient(patientId);
  return result.when(
    success: (payments) => payments,
    failure: (AppException exception) => throw exception,
  );
}

/// Controller managing form submission state for the record payment screen.
@riverpod
class RecordPaymentController extends _$RecordPaymentController {
  @override
  FutureOr<void> build() {
    // Initial state is idle.
  }

  /// Submits the recorded payment to the database.
  ///
  /// The corresponding patient balance increments are applied atomically
  /// by the Postgres `handle_payment_package_sync()` trigger so this
  /// controller does not need to know about which bucket was credited.
  ///
  /// After the async repository call completes, [ref.mounted] is
  /// checked before any state mutation or provider invalidation.
  /// If the notifier was disposed while waiting (e.g. the calling
  /// sheet was popped), the result is returned to the caller directly
  /// so that the sheet can handle success / failure on its own.
  Future<Result<void>> submitPayment({
    required String patientId,
    required double amount,
    required String reason,
    int sessionBalanceAdded = 0,
    int tractionBalanceAdded = 0,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(paymentRepositoryProvider);
    final currentUser = ref.read(currentUserProvider).value;

    final payment = PaymentRecord(
      id: '',
      patientId: patientId,
      amount: amount,
      reason: reason,
      recordedBy: currentUser?.id,
      recordedAt: DateTime.now(),
      sessionBalanceAdded: sessionBalanceAdded,
      tractionBalanceAdded: tractionBalanceAdded,
    );

    final Result<void> result = await repo.recordPayment(payment);
    if (!ref.mounted) return result;

    state = result.when(
      success: (_) {
        ref.invalidate(patientDetailProvider(patientId));
        ref.invalidate(patientPaymentsProvider(patientId));
        return const AsyncValue.data(null);
      },
      failure: (error) => AsyncValue.error(error, StackTrace.current),
    );

    return result;
  }

  /// Deletes a payment record and invalidates dependent providers.
  Future<Result<void>> deletePayment({
    required String paymentId,
    required String patientId,
  }) async {
    final repo = ref.read(paymentRepositoryProvider);
    final result = await repo.deletePayment(paymentId);
    if (!ref.mounted) return result;
    result.when(
      success: (_) {
        ref.invalidate(patientPaymentsProvider(patientId));
        ref.invalidate(patientDetailProvider(patientId));
      },
      failure: (_) {},
    );
    return result;
  }
}
