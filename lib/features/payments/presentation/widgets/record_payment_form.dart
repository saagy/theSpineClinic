import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/payments/presentation/record_payment_controller.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_form_fields.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/record_payment_patient_header.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

class RecordPaymentForm extends ConsumerStatefulWidget {
  const RecordPaymentForm({super.key, required this.patientId});
  final String patientId;

  @override
  ConsumerState<RecordPaymentForm> createState() => _RecordPaymentFormState();
}

class _RecordPaymentFormState extends ConsumerState<RecordPaymentForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> _submit(Patient patient) async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;
    final String reasonType = values['reason_type'] as String;
    final (reason, sessionAdded, tractionAdded) = _paymentDetails(
      values,
      reasonType,
    );
    final result = await ref
        .read(recordPaymentControllerProvider.notifier)
        .submitPayment(
          patientId: patient.id,
          amount: double.parse(values['amount'] as String),
          reason: reason,
          sessionBalanceAdded: sessionAdded,
          tractionBalanceAdded: tractionAdded,
          totalPrice: _totalPrice(values),
        );
    if (!mounted) return;
    result.when(
      success: (_) {
        AppSnackbar.show(
          context,
          message: AppStrings.paymentRecordedSuccess,
          variant: AppSnackbarVariant.success,
        );
        Navigator.of(context).pop();
      },
      failure: (error) => AppSnackbar.show(
        context,
        message: error.message,
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  (String, int, int) _paymentDetails(
    Map<String, dynamic> values,
    String reasonType,
  ) {
    final String reason = switch (reasonType) {
      AppStrings.paymentReasonOther => values['custom_reason'] as String,
      _ => reasonType,
    };
    int sessionAdded = 0;
    int tractionAdded = 0;
    final bool addToPackage = (values['add_to_package'] as bool?) ?? false;
    final bool assessment =
        reasonType == AppStrings.paymentReasonInitialAssessment ||
        reasonType == AppStrings.paymentReasonReassessment;
    if (addToPackage && !assessment) {
      final String sText = (values['session_added'] as String? ?? '').trim();
      final String tText = (values['traction_added'] as String? ?? '').trim();
      sessionAdded = sText.isEmpty ? 0 : (int.tryParse(sText) ?? 0);
      tractionAdded = tText.isEmpty ? 0 : (int.tryParse(tText) ?? 0);
    }
    return (reason, sessionAdded, tractionAdded);
  }

  double? _totalPrice(Map<String, dynamic> values) {
    if ((values['is_partial'] as bool?) != true) return null;
    final String? total = values['total_price'] as String?;
    return total == null || total.isEmpty ? null : double.tryParse(total);
  }

  @override
  Widget build(BuildContext context) {
    final asyncPatient = ref.watch(patientDetailProvider(widget.patientId));
    final controllerState = ref.watch(recordPaymentControllerProvider);
    return asyncPatient.when(
      loading: () => _loadingScaffold(context),
      error: (error, _) => _errorScaffold(
        error,
        () => ref.invalidate(patientDetailProvider(widget.patientId)),
      ),
      data: (patient) => _formScaffold(patient, controllerState),
    );
  }

  Widget _formScaffold(Patient patient, AsyncValue<void> controllerState) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _appBar(context),
      body: LoadingOverlay(
        isLoading: controllerState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RecordPaymentPatientHeader(patient: patient),
                const SizedBox(height: AppSizes.p24),
                PaymentFormFields(
                  enabled: !controllerState.isLoading,
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
    );
  }

  Widget _loadingScaffold(BuildContext context, {bool appBar = false}) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar ? _appBar(context) : null,
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _errorScaffold(Object error, VoidCallback onRetry) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.recordPayment)),
      body: ErrorView(
        exception: error is AppException
            ? error
            : const UnknownException(
                message: AppStrings.errorDatabaseQueryFailed,
              ),
        onRetry: onRetry,
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      title: const Text(AppStrings.recordPayment),
    );
  }
}
