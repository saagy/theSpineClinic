import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/record_payment_form.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

class RecordPaymentScreen extends ConsumerWidget {
  const RecordPaymentScreen({super.key, required this.patientId});
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    return asyncUser.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(
                  message: AppStrings.errorDatabaseQueryFailed,
                ),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (user) {
        if (user == null || !user.canHandlePayments) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const ErrorView(
              exception: UnknownException(
                message: AppStrings.paymentAccessDenied,
                code: 'security/blocked',
              ),
            ),
          );
        }
        return RecordPaymentForm(patientId: patientId);
      },
    );
  }
}
