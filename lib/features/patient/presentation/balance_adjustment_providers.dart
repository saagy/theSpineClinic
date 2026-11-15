import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/core/network/supabase_service.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/data/balance_adjustment_repository_impl.dart';
import 'package:spine_clinic_app/features/patient/domain/balance_adjustment.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

part 'balance_adjustment_providers.g.dart';

/// Payment staff and the admin may correct balances by hand.
bool canAdjustBalances(Staff? user) => user != null && user.isActive && user.canHandlePayments;

@Riverpod(keepAlive: true)
BalanceAdjustmentRepository balanceAdjustmentRepository(Ref ref) =>
    BalanceAdjustmentRepositoryImpl(supabaseService: SupabaseService.instance);

/// A patient's balance corrections, newest first.
@riverpod
Future<List<BalanceAdjustment>> balanceAdjustments(Ref ref, String patientId) async {
  final result = await ref.watch(balanceAdjustmentRepositoryProvider).getAdjustments(patientId);
  return result.when(success: (data) => data, failure: (error) => throw error);
}

/// Saves a correction. Kept alive so a save started from a dialog finishes
/// its refreshes even after the dialog closes.
@Riverpod(keepAlive: true)
class BalanceAdjustmentController extends _$BalanceAdjustmentController {
  @override
  bool build() => false;

  Future<Result<void>> adjust({
    required String patientId,
    required int expectedPt,
    required int expectedTraction,
    required int pt,
    required int traction,
    required String reason,
  }) async {
    if (!canAdjustBalances(ref.read(currentUserProvider).value)) {
      return const Failure(
        DatabaseException(
          code: 'db/permission-denied',
          message: 'Balance adjustment denied',
          userMessageKey: 'error_database_permission_denied',
        ),
      );
    }
    final Result<void> result = await ref
        .read(balanceAdjustmentRepositoryProvider)
        .adjust(
          patientId: patientId,
          expectedPt: expectedPt,
          expectedTraction: expectedTraction,
          pt: pt,
          traction: traction,
          reason: reason,
        );
    // Refresh on failure too: a `balance_changed` refusal means the shown
    // balances are out of date.
    ref.invalidate(patientDetailProvider(patientId));
    if (result is Success<void>) {
      ref.invalidate(balanceAdjustmentsProvider(patientId));
      ref.invalidate(patientListProvider);
      ref.invalidate(availablePackageBalanceProvider(patientId));
      for (final AppointmentType type in AppointmentType.values) {
        ref.invalidate(availableBalanceForTypeProvider((patientId: patientId, type: type)));
      }
    }
    return result;
  }
}
