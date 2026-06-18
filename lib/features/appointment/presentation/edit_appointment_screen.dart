import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/edit_appointment_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_form_fields.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_selector_dropdown.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/selected_doctors_chips.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Screen for editing an existing appointment's details.
class EditAppointmentScreen extends ConsumerWidget {
  const EditAppointmentScreen({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    final user = asyncUser.value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!asyncUser.isLoading && user == null) {
        AppSnackbar.show(context,
            message: AppStrings.accessDenied, variant: AppSnackbarVariant.error);
        context.pop();
      }
    });

    if (asyncUser.isLoading || user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final detailAsync = ref.watch(appointmentDetailControllerProvider(appointmentId));

    final Widget body;
    if (detailAsync.isLoading && !detailAsync.hasValue) {
      body = const Padding(
        padding: EdgeInsets.all(AppSizes.p16),
        child: SkeletonTileList(count: 5),
      );
    } else if (detailAsync.hasError && !detailAsync.hasValue) {
      final error = detailAsync.error!;
      body = ErrorView(
        exception: error is AppException
            ? error
            : AppException.fromSupabaseException(error),
        onRetry: () => ref.invalidate(appointmentDetailControllerProvider(appointmentId)),
      );
    } else {
      final state = detailAsync.value!;
      body = _EditAppointmentFormBody(
        appointment: state.appointment,
        patient: state.patient,
        initialDoctors: state.activeDoctors.map((d) => d.doctor).toList(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.editAppointment),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: const AppBackButton(),
      ),
      body: body,
    );
  }
}

class _EditAppointmentFormBody extends ConsumerStatefulWidget {
  const _EditAppointmentFormBody({
    required this.appointment,
    required this.patient,
    required this.initialDoctors,
  });

  final Appointment appointment;
  final Patient patient;
  final List<Staff> initialDoctors;

  @override
  ConsumerState<_EditAppointmentFormBody> createState() => _EditAppointmentFormBodyState();
}

class _EditAppointmentFormBodyState extends ConsumerState<_EditAppointmentFormBody> {
  final _formKey = GlobalKey<FormState>();
  late AppointmentType _selectedType;
  late bool _usePackage;
  late DateTime? _selectedDate;
  late TimeOfDay? _selectedTime;
  late List<Staff> _assignedDoctors;
  String? _dateErrorText;
  String? _timeErrorText;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.appointment.type;
    _usePackage = widget.appointment.usePackage;
    _selectedDate = widget.appointment.scheduledAt.toLocal();
    _selectedTime = TimeOfDay.fromDateTime(widget.appointment.scheduledAt.toLocal());
    _assignedDoctors = List.from(widget.initialDoctors);
  }

  Future<void> _submit() async {
    setState(() {
      _dateErrorText = _selectedDate == null ? 'Date required' : null;
      _timeErrorText = _selectedTime == null ? 'Time required' : null;
    });
    if (_dateErrorText != null || _timeErrorText != null) return;
    if (_assignedDoctors.isEmpty) {
      AppSnackbar.show(context, message: AppStrings.noAssignedDoctors, variant: AppSnackbarVariant.error);
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

    final result = await ref.read(editAppointmentControllerProvider.notifier).updateAppointment(
          appointment: updatedAppt,
          doctorIds: _assignedDoctors.map((d) => d.id).toList(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        AppSnackbar.show(context, message: AppStrings.appointmentUpdated, variant: AppSnackbarVariant.success);
        context.pop();
      },
      failure: (e) {
        AppSnackbar.show(
          context,
          message: AppStrings.fromKey(e.userMessageKey),
          variant: AppSnackbarVariant.error,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isScheduled = widget.appointment.status == AppointmentStatus.scheduled;

    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BookingFormFields(
                preselectedPatient: widget.patient,
                onPatientTap: null,
                selectedType: _selectedType,
                onTypeChanged: (type) => setState(() => _selectedType = type),
                isRecurring: false,
                onRecurringChanged: (_) {},
                selectedDate: _selectedDate,
                onDateChanged: (d) => setState(() => _selectedDate = d),
                selectedTime: _selectedTime,
                onTimeChanged: (t) => setState(() => _selectedTime = t),
                dateErrorText: _dateErrorText,
                timeErrorText: _timeErrorText,
                showRecurringToggle: false,
              ),
              const SizedBox(height: AppSizes.p16),
              DoctorSelectorDropdown(
                selectedDoctors: _assignedDoctors,
                isEnabled: true,
                onDoctorSelected: (doc) {
                  if (_assignedDoctors.any((d) => d.id == doc.id)) return;
                  setState(() => _assignedDoctors = [..._assignedDoctors, doc]);
                },
                onDoctorRemoved: (doc) {
                  setState(() => _assignedDoctors = _assignedDoctors.where((d) => d.id != doc.id).toList());
                },
              ),
              const SizedBox(height: AppSizes.p16),
              if (_assignedDoctors.isNotEmpty) ...[
                SelectedDoctorsChips(
                  doctors: _assignedDoctors,
                  onRemoveDoctor: (doc) => setState(() => _assignedDoctors = _assignedDoctors.where((d) => d.id != doc.id).toList()),
                ),
                const SizedBox(height: AppSizes.p16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.usePackageBalance, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                        if (!isScheduled) ...[
                          const SizedBox(height: AppSizes.p4),
                          Text(
                            AppStrings.usePackageChangeWarning,
                            style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Switch(
                    value: _usePackage,
                    onChanged: isScheduled ? (v) => setState(() => _usePackage = v) : null,
                    activeThumbColor: AppColors.primary,
                  ),
                ],
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
    );
  }
}
