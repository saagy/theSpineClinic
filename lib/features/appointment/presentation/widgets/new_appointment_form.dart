/// Modern new-appointment form with patient selector, pill chips,
/// searchable doctor multi-select sheet, and receipt-style ledger.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_form_fields.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_slots_preview.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_submit_helper.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/date_recurrence_utils.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/recurring_pattern_picker.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_balance_diagnostics.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/patient_search_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/recurrence_guide.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/app_doctor_multi_select_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

class NewAppointmentForm extends ConsumerStatefulWidget {
  const NewAppointmentForm({super.key, this.preselectedPatientId});
  final String? preselectedPatientId;
  @override
  ConsumerState<NewAppointmentForm> createState() =>
      _NewAppointmentFormState();
}

class _NewAppointmentFormState extends ConsumerState<NewAppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _doctorFieldKey = GlobalKey<FormFieldState<List<Staff>>>();
  late final TextEditingController _sessionsController;
  AppointmentType _selectedType = AppointmentType.normalPtSession;
  bool _isRecurring = false, _isSubmitting = false, _usePackage = true;
  bool _isFetchingDoctors = false;
  bool _doctorFieldEnabled = true;
  DateTime? _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  Set<int> _selectedWeekdays = <int>{};
  String? _dateErrorText, _timeErrorText, _daysErrorText;
  String? _patientId;

  static const _fetchTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _sessionsController = TextEditingController();
    if (widget.preselectedPatientId != null &&
        widget.preselectedPatientId!.trim().length == 36) {
      _patientId = widget.preselectedPatientId!.trim();
      _doctorFieldEnabled = false;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _fetchAssignedDoctors());
    }
  }

  @override
  void dispose() {
    _sessionsController.dispose();
    super.dispose();
  }

  Future<void> _fetchAssignedDoctors() async {
    if (_patientId == null) return;
    setState(() => _isFetchingDoctors = true);
    try {
      final result = await ref
          .read(appointmentRepositoryProvider)
          .getAssignedDoctors(_patientId!)
          .timeout(_fetchTimeout);
      if (!mounted) return;
      result.when(
        success: (docs) {
          final activeDocs = docs.where((s) => s.isActive).toList();
          _doctorFieldKey.currentState?.didChange(activeDocs);
          setState(() {
            _isFetchingDoctors = false;
            _doctorFieldEnabled = true;
          });
        },
        failure: (e) {
          setState(() {
            _isFetchingDoctors = false;
            _doctorFieldEnabled = true;
          });
          AppSnackbar.show(
            context,
            message: AppStrings.fromKey(e.userMessageKey),
            variant: AppSnackbarVariant.error,
          );
        },
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isFetchingDoctors = false;
        _doctorFieldEnabled = true;
      });
      AppSnackbar.show(
        context,
        message: 'Doctor list took too long — select manually.',
        variant: AppSnackbarVariant.info,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFetchingDoctors = false;
        _doctorFieldEnabled = true;
      });
    }
  }

  void _onPatientSelected(Patient patient) {
    _doctorFieldKey.currentState?.didChange([]);
    setState(() {
      _patientId = patient.id;
      _doctorFieldEnabled = false;
      _isFetchingDoctors = true;
    });
    _fetchAssignedDoctors();
  }

  List<DateTime> get _computedSlots => _selectedDate == null
      ? const []
      : (!_isRecurring
          ? [_selectedDate!]
          : DateRecurrenceUtils.generateRecurrenceSlots(
              startDate: _selectedDate!,
              weekdays: _selectedWeekdays,
              totalSessions: int.tryParse(_sessionsController.text) ?? 0));

  Future<void> _submitForm() async {
    setState(() {
      _dateErrorText = _selectedDate == null ? AppStrings.dateRequired : null;
      _timeErrorText = _selectedTime == null ? AppStrings.timeRequired : null;
      _daysErrorText = _isRecurring && _selectedWeekdays.isEmpty
          ? AppStrings.daysRequired
          : null;
    });
    if (_dateErrorText != null ||
        _timeErrorText != null ||
        _daysErrorText != null) {
      return;
    }
    if (_patientId == null) {
      AppSnackbar.show(context,
          message: AppStrings.patientRequired,
          variant: AppSnackbarVariant.error);
      return;
    }
    final doctors = _doctorFieldKey.currentState?.value ?? [];
    if (doctors.isEmpty) {
      AppSnackbar.show(context,
          message: AppStrings.noAssignedDoctors,
          variant: AppSnackbarVariant.error);
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await BookingSubmitHelper.executeBooking(
      repo: ref.read(appointmentRepositoryProvider),
      patientId: _patientId!,
      type: _selectedType,
      slots: _computedSlots,
      time: _selectedTime!,
      creatorId: ref.read(currentUserProvider).value?.id,
      doctors: doctors,
      usePackage: _usePackage,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        ref.invalidate(todayAppointmentsProvider);
        ref.invalidate(patientAppointmentsProvider(_patientId!));
        ref.invalidate(patientDetailProvider(_patientId!));
        ref.invalidate(
            futureScheduledAppointmentsCountProvider(_patientId!));
        ref.invalidate(availableBalanceForTypeProvider(
          (patientId: _patientId!, type: _selectedType),
        ));
        AppSnackbar.show(
          context,
          message: _isRecurring
              ? AppStrings.bookingRecurringSuccess
              : AppStrings.bookingSuccess,
          variant: AppSnackbarVariant.success,
        );
        context.pop();
      },
      failure: (e) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(e.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  Patient? _resolvePatient() {
    if (_patientId == null) return null;
    final async = ref.watch(patientDetailProvider(_patientId!));
    return async.value;
  }

  @override
  Widget build(BuildContext context) {
    final patient = _resolvePatient();
    final isPatientValid = _patientId != null;
    final availableAsync = isPatientValid
        ? ref.watch(availableBalanceForTypeProvider(
            (patientId: _patientId!, type: _selectedType),
          ))
        : null;
    final proposedCount = _usePackage ? _computedSlots.length : 0;
    final isSubmissionBlocked = isPatientValid &&
        proposedCount > 0 &&
        (availableAsync == null ||
            availableAsync.isLoading ||
            availableAsync.hasError ||
            proposedCount > (availableAsync.value ?? 0));

    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BookingFormFields(
                preselectedPatient: patient,
                onPatientTap: () => _openPatientSearch(context),
                selectedType: _selectedType,
                onTypeChanged: (type) => setState(() {
                  _selectedType = type;
                  // Assessments never deduct packages: lock the toggle off.
                  if (!type.affectsPackageBalance) {
                    _usePackage = false;
                  }
                }),
                isRecurring: _isRecurring,
                onRecurringChanged: (v) =>
                    setState(() => _isRecurring = v),
                selectedDate: _selectedDate,
                onDateChanged: (d) => setState(() => _selectedDate = d),
                selectedTime: _selectedTime,
                onTimeChanged: (t) => setState(() => _selectedTime = t),
                dateErrorText: _dateErrorText,
                timeErrorText: _timeErrorText,
              ),
              if (_isRecurring) ...[
                const SizedBox(height: AppSizes.p16),
                if (_selectedDate != null &&
                    _selectedWeekdays.isNotEmpty)
                  RecurrenceGuide(
                    startDate: _selectedDate!,
                    selectedWeekdays: _selectedWeekdays,
                    totalSessions:
                        int.tryParse(_sessionsController.text) ?? 0,
                    slots: _computedSlots,
                  ),
                RecurringPatternPicker(
                  selectedWeekdays: _selectedWeekdays,
                  onWeekdaysChanged: (d) =>
                      setState(() => _selectedWeekdays = d),
                  sessionsController: _sessionsController,
                  daysErrorText: _daysErrorText,
                ),
              ],
              const SizedBox(height: AppSizes.p16),
              if (_isFetchingDoctors)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.p8),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: AppSizes.iconDefault,
                        height: AppSizes.iconDefault,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSizes.p12),
                      Text(
                        'Loading assigned doctors…',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              AppDoctorMultiSelectField(
                key: _doctorFieldKey,
                initialValue: const [],
                enabled: _doctorFieldEnabled,
                onSavedDoctors: (_) {},
                onChanged: (_) {},
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return AppStrings.atLeastOneDoctorRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.p16),
              if (_selectedType.affectsPackageBalance)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.usePackageBalance,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textPrimary)),
                    Switch(
                      value: _usePackage,
                      onChanged: (v) => setState(() => _usePackage = v),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p12, vertical: AppSizes.p8),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: AppSizes.iconSmall, color: AppColors.info),
                      const SizedBox(width: AppSizes.p8),
                      Expanded(
                        child: Text(
                          AppStrings.paidSeparately,
                          style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isPatientValid) ...[
                const SizedBox(height: AppSizes.p24),
                AppointmentBalanceDiagnostics(
                  patientId: _patientId!,
                  appointmentType: _selectedType,
                  requestedCount: proposedCount,
                ),
              ],
              if (_computedSlots.isNotEmpty) ...[
                const SizedBox(height: AppSizes.p24),
                BookingSlotsPreview(
                  slots: _computedSlots,
                  timeOfDay: _selectedTime,
                  usePackage: _usePackage,
                ),
              ],
              const SizedBox(height: AppSizes.p32),
              AppButton(
                labelText: AppStrings.save,
                onPressed: (isSubmissionBlocked || _isSubmitting)
                    ? null
                    : _submitForm,
                isLoading: _isSubmitting,
                debounceMs: 1000,
              ),
              const SizedBox(height: AppSizes.p48),
            ],
          ),
        ),
      ),
    );
  }

  void _openPatientSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.r24),
        ),
      ),
      builder: (ctx) => PatientSearchSheet(
        onSelected: (p) {
          _onPatientSelected(p);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}
