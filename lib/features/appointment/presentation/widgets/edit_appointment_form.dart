/// Form body for editing an appointment's type, doctor assignment, and
/// package toggle. Extracted from [EditAppointmentScreen] to keep file
/// sizes under the 200-line limit.
library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/edit_appointment_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_form_fields.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/app_doctor_multi_select_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

/// Form body for the edit-appointment flow.
class EditAppointmentForm extends ConsumerStatefulWidget {
  const EditAppointmentForm({
    super.key,
    required this.appointment,
    required this.patient,
    required this.initialDoctors,
  });

  final Appointment appointment;
  final Patient patient;
  final List<Staff> initialDoctors;

  @override
  ConsumerState<EditAppointmentForm> createState() =>
      _EditAppointmentFormState();
}

class _EditAppointmentFormState extends ConsumerState<EditAppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _doctorFieldKey = GlobalKey<FormFieldState<List<Staff>>>();
  late AppointmentType _selectedType;
  late bool _usePackage;
  late DateTime? _selectedDate;
  late TimeOfDay? _selectedTime;
  String? _dateErrorText;
  String? _timeErrorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.appointment.type;
    _usePackage = widget.appointment.usePackage;
    _selectedDate = widget.appointment.scheduledAt.toLocal();
    _selectedTime =
        TimeOfDay.fromDateTime(widget.appointment.scheduledAt.toLocal());
  }

  Future<void> _submit() async {
    setState(() {
      _dateErrorText = _selectedDate == null ? 'Date required' : null;
      _timeErrorText = _selectedTime == null ? 'Time required' : null;
    });
    if (_dateErrorText != null || _timeErrorText != null) return;

    final doctors = _doctorFieldKey.currentState?.value ?? [];
    if (doctors.isEmpty) {
      AppSnackbar.show(context,
          message: AppStrings.noAssignedDoctors,
          variant: AppSnackbarVariant.error);
      return;
    }

    setState(() => _isSubmitting = true);

    final updatedScheduledAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    ).toUtc();

    final updatedAppt = widget.appointment.copyWith(
      type: _selectedType,
      usePackage: _usePackage,
      scheduledAt: updatedScheduledAt,
    );

    try {
      final result = await ref
          .read(editAppointmentControllerProvider.notifier)
          .updateAppointment(
            appointment: updatedAppt,
            doctorIds: doctors.map((d) => d.id).toList(),
          );

      if (!mounted) return;

      result.when(
        success: (_) {
          ref.invalidate(
              appointmentDetailControllerProvider(widget.appointment.id));
          AppSnackbar.show(context,
              message: AppStrings.appointmentUpdated,
              variant: AppSnackbarVariant.success);
          context.pop();
        },
        failure: (e) {
          AppSnackbar.show(context,
              message: AppStrings.fromKey(e.userMessageKey),
              variant: AppSnackbarVariant.error);
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.show(context,
          message: AppStrings.errorUnknown,
          variant: AppSnackbarVariant.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScheduled =
        widget.appointment.status == AppointmentStatus.scheduled;

    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isScheduled) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSizes.p16),
                      decoration: BoxDecoration(
                        color: ClinicColors.of(context).warningContainer,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppSizes.r16),
                        ),
                        border: Border.all(
                          color: ClinicColors.of(context).warning.withAlpha(40),
                          width: AppSizes.borderWidth,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: ClinicColors.of(context).warning,
                            size: AppSizes.iconDefault,
                          ),
                          const SizedBox(width: AppSizes.p12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Checked-In Appointment',
                                  style: AppTextStyles.bodyBold.copyWith(
                                    color: ClinicColors.of(context).warning,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.p4),
                                Text(
                                  'To change the appointment type or billing options, undo the check-in first.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.p16),
                  ],
                  BookingFormFields(
                    preselectedPatient: widget.patient,
                    onPatientTap: null,
                    selectedType: _selectedType,
                    onTypeChanged: (type) =>
                        setState(() {
                          _selectedType = type;
                          if (!type.affectsPackageBalance) {
                            _usePackage = false;
                          }
                        }),
                    isRecurring: false,
                    onRecurringChanged: (_) {},
                    selectedDate: _selectedDate,
                    onDateChanged: (d) => setState(() => _selectedDate = d),
                    selectedTime: _selectedTime,
                    onTimeChanged: (t) => setState(() => _selectedTime = t),
                    dateErrorText: _dateErrorText,
                    timeErrorText: _timeErrorText,
                    showRecurringToggle: false,
                    enabled: isScheduled,
                  ),
                  const SizedBox(height: AppSizes.p16),
                  
                  // ── Card 3: Provider & Billing ──
                  Container(
                    padding: const EdgeInsets.all(AppSizes.p16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
                      border: Border.all(color: Theme.of(context).colorScheme.outline, width: AppSizes.borderWidth),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Provider & Billing',
                          style: AppTextStyles.captionMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppSizes.p12),
                        AppDoctorMultiSelectField(
                          key: _doctorFieldKey,
                          initialValue: widget.initialDoctors,
                          enabled: true,
                          onSavedDoctors: (_) {},
                          onChanged: (_) {},
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'At least one doctor is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSizes.p16),
                        if (_selectedType.affectsPackageBalance)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(AppStrings.usePackageBalance,
                                        style: AppTextStyles.body.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface)),
                                    if (!isScheduled) ...[
                                      const SizedBox(height: AppSizes.p4),
                                      Text(AppStrings.usePackageChangeWarning,
                                          style: AppTextStyles.caption.copyWith(
                                              color: ClinicColors.of(context).warning)),
                                    ],
                                  ],
                                ),
                              ),
                              Switch(
                                value: _usePackage,
                                onChanged: isScheduled
                                    ? (v) => setState(() => _usePackage = v)
                                    : null,
                                activeThumbColor: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.p12,
                              vertical: AppSizes.p8,
                            ),
                            decoration: BoxDecoration(
                              color: ClinicColors.of(context).infoContainer,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(AppSizes.r12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: AppSizes.iconSmall,
                                  color: ClinicColors.of(context).info,
                                ),
                                const SizedBox(width: AppSizes.p8),
                                Expanded(
                                  child: Text(
                                    AppStrings.paidSeparately,
                                    style: AppTextStyles.bodySecondary.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p32),
                  AppButton(
                    labelText: AppStrings.save,
                    onPressed: _isSubmitting ? null : _submit,
                    isLoading: _isSubmitting,
                    debounceMs: 1000,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
