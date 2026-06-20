import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/payments/domain/clinic_package.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_form_fields.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Screen allowing receptionists/admins to record a patient payment.
/// Enforces absolute access control against doctor role tier on mount.
class RecordPaymentScreen extends ConsumerWidget {
  /// Creates a [RecordPaymentScreen].
  const RecordPaymentScreen({super.key, required this.patientId});

  /// The target patient ID passed via routing.
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);

    return asyncUser.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
          onRetry: () => ref.invalidate(currentUserProvider),
        ),
      ),
      data: (user) {
        if (user == null || user.role == UserRole.doctor) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: ErrorView(
              exception: UnknownException(
                message: AppStrings.doctorAccessBlocked,
                code: 'security/blocked',
              ),
            ),
          );
        }
        return _RecordPaymentForm(patientId: patientId);
      },
    );
  }
}

class _RecordPaymentForm extends ConsumerStatefulWidget {
  const _RecordPaymentForm({required this.patientId});

  final String patientId;

  @override
  ConsumerState<_RecordPaymentForm> createState() => _RecordPaymentFormState();
}

class _RecordPaymentFormState extends ConsumerState<_RecordPaymentForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submit(Patient patient) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      final double amount = double.parse(values['amount'] as String);
      final String reasonType = values['reason_type'] as String;

      String reason;
      int sessionAdded = 0;
      int tractionAdded = 0;
      if (reasonType == AppStrings.paymentReasonPackage) {
        final ClinicPackage pkg = values['package'] as ClinicPackage;
        reason = 'Package (${pkg.name})';
      } else if (reasonType == AppStrings.paymentReasonOther) {
        reason = values['custom_reason'] as String;
      } else {
        reason = reasonType;
      }

      // Add-balance applies to ALL non-assessment reasons, but only when
      // the toggle is on. The trigger handles the actual patient row update.
      // Empty fields silently map to 0 — "leave empty to skip" UX.
      final bool addToPackage =
          (values['add_to_package'] as bool?) ?? false;
      if (addToPackage &&
          reasonType != AppStrings.paymentReasonInitialAssessment &&
          reasonType != AppStrings.paymentReasonReassessment) {
        final String sText = (values['session_added'] as String? ?? '').trim();
        final String tText = (values['traction_added'] as String? ?? '').trim();
        sessionAdded = sText.isEmpty ? 0 : (int.tryParse(sText) ?? 0);
        tractionAdded = tText.isEmpty ? 0 : (int.tryParse(tText) ?? 0);
      }

      final result = await ref.read(recordPaymentControllerProvider.notifier).submitPayment(
            patientId: patient.id,
            amount: amount,
            reason: reason,
            sessionBalanceAdded: sessionAdded,
            tractionBalanceAdded: tractionAdded,
          );

      if (mounted) {
        result.when(
          success: (_) {
            AppSnackbar.show(
              context,
              message: AppStrings.paymentRecordedSuccess,
              variant: AppSnackbarVariant.success,
            );
            Navigator.of(context).pop();
          },
          failure: (error) {
            AppSnackbar.show(
              context,
              message: error.message,
              variant: AppSnackbarVariant.error,
            );
          },
        );
      }
    }
  }

  Widget _buildPatientHeader(Patient patient) {
    return SectionCard(
      title: AppStrings.patientDisplayName,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            radius: AppSizes.p24,
            child: Text(
              patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : '?',
              style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSizes.p16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSizes.p4),
                Text(
                  patient.phoneNumber,
                  style: AppTextStyles.bodySecondary.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncPatient = ref.watch(patientDetailProvider(widget.patientId));
    final asyncPackages = ref.watch(clinicPackagesProvider);
    final controllerState = ref.watch(recordPaymentControllerProvider);

    return asyncPatient.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.recordPayment)),
        body: ErrorView(
          exception: error is AppException
              ? error
              : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
          onRetry: () => ref.invalidate(patientDetailProvider(widget.patientId)),
        ),
      ),
      data: (patient) => asyncPackages.when(
        loading: () => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: const Text(AppStrings.recordPayment),
          ),
          body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text(AppStrings.recordPayment)),
          body: ErrorView(
            exception: error is AppException
                ? error
                : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
            onRetry: () => ref.invalidate(clinicPackagesProvider),
          ),
        ),
        data: (packages) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            title: const Text(AppStrings.recordPayment),
          ),
          body: LoadingOverlay(
            isLoading: controllerState.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPatientHeader(patient),
                    const SizedBox(height: AppSizes.p24),
                    PaymentFormFields(
                      enabled: !controllerState.isLoading,
                      packages: packages,
                      formKey: _formKey,
                    ),
                    const SizedBox(height: AppSizes.p32),
                    AppButton(
                      labelText: AppStrings.save,
                      isLoading: controllerState.isLoading,
                      onPressed: () => _submit(patient),
                      debounceMs: 1000,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
