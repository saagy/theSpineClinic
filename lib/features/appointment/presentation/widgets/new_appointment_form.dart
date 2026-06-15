import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_form_fields.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_slots_preview.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_submit_helper.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/medical_records_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/date_recurrence_utils.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/recurring_pattern_picker.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/selected_doctors_chips.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_balance_diagnostics.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_selector_dropdown.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

class NewAppointmentForm extends ConsumerStatefulWidget {
  const NewAppointmentForm({super.key, this.preselectedPatientId});
  final String? preselectedPatientId;
  @override
  ConsumerState<NewAppointmentForm> createState() => _NewAppointmentFormState();
}

class _NewAppointmentFormState extends ConsumerState<NewAppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _patientIdController, _notesController, _sessionsController;
  AppointmentType _selectedType = AppointmentType.session;
  bool _isRecurring = false, _isLoadingDoctors = false, _isSubmitting = false, _usePackage = true;
  DateTime? _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  Set<int> _selectedWeekdays = <int>{};
  List<Staff> _assignedDoctors = <Staff>[];
  String? _dateErrorText, _timeErrorText, _daysErrorText;

  @override
  void initState() {
    super.initState();
    _patientIdController = TextEditingController(text: widget.preselectedPatientId)..addListener(_onPatientIdChanged);
    _notesController = TextEditingController();
    _sessionsController = TextEditingController();
    if (widget.preselectedPatientId != null && widget.preselectedPatientId!.trim().length == 36) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAssignedDoctors(widget.preselectedPatientId!.trim()));
    }
  }

  @override
  void dispose() {
    _patientIdController.removeListener(_onPatientIdChanged);
    _patientIdController.dispose();
    _notesController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  void _onPatientIdChanged() {
    final text = _patientIdController.text.trim();
    if (text.length == 36) {
      _fetchAssignedDoctors(text);
    } else if (_assignedDoctors.isNotEmpty) {
      setState(() => _assignedDoctors = const []);
    }
  }

  Future<void> _fetchAssignedDoctors(String patientId) async {
    setState(() => _isLoadingDoctors = true);
    final Result<List<Staff>> result = await ref.read(appointmentRepositoryProvider).getAssignedDoctors(patientId);
    if (!mounted) return;
    result.when(
      success: (doctors) => setState(() {
        _assignedDoctors = doctors;
        _isLoadingDoctors = false;
        if (_selectedType == AppointmentType.checkUp) _autoSelectSuperAdmin();
      }),
      failure: (error) {
        setState(() => _isLoadingDoctors = false);
        AppSnackbar.show(context, message: AppStrings.fromKey(error.userMessageKey), variant: AppSnackbarVariant.error);
      },
    );
  }

  void _autoSelectSuperAdmin() {
    final activeDocs = ref.read(activeDoctorsProvider).value ?? [];
    try {
      final admin = activeDocs.firstWhere((doc) => doc.role == UserRole.superAdmin);
      setState(() => _assignedDoctors = [admin]);
    } catch (_) {}
  }

  List<DateTime> get _computedSlots => _selectedDate == null ? const [] : (!_isRecurring ? [_selectedDate!] : DateRecurrenceUtils.generateRecurrenceSlots(
      startDate: _selectedDate!, weekdays: _selectedWeekdays, totalSessions: int.tryParse(_sessionsController.text) ?? 0));

  Future<void> _submitForm() async {
    setState(() {
      _dateErrorText = _selectedDate == null ? AppStrings.dateRequired : null;
      _timeErrorText = _selectedTime == null ? AppStrings.timeRequired : null;
      _daysErrorText = _isRecurring && _selectedWeekdays.isEmpty ? AppStrings.daysRequired : null;
    });
    if (!(_formKey.currentState?.validate() ?? false) || _dateErrorText != null || _timeErrorText != null || _daysErrorText != null) return;
    if (_assignedDoctors.isEmpty) {
      AppSnackbar.show(context, message: AppStrings.noAssignedDoctors, variant: AppSnackbarVariant.error);
      return;
    }
    setState(() => _isSubmitting = true);
    final Result<void> result = await BookingSubmitHelper.executeBooking(
      repo: ref.read(appointmentRepositoryProvider),
      notesRepo: ref.read(patientNotesRepositoryProvider),
      patientId: _patientIdController.text.trim(), type: _selectedType, slots: _computedSlots,
      time: _selectedTime!, notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      creatorId: ref.read(currentUserProvider).value?.id, doctors: _assignedDoctors, usePackage: _usePackage,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        final pId = _patientIdController.text.trim();
        ref.invalidate(todayAppointmentsProvider);
        ref.invalidate(patientAppointmentsProvider(pId));
        ref.invalidate(patientDetailProvider(pId));
        ref.invalidate(futureScheduledAppointmentsCountProvider(pId));
        ref.invalidate(availablePackageBalanceProvider(pId));
        AppSnackbar.show(context, message: _isRecurring ? AppStrings.bookingRecurringSuccess : AppStrings.bookingSuccess, variant: AppSnackbarVariant.success);
        context.pop();
      },
      failure: (_) => AppSnackbar.show(context, message: AppStrings.bookingError, variant: AppSnackbarVariant.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientId = _patientIdController.text.trim();
    final isPatientValid = patientId.length == 36;
    final activeDocs = ref.watch(activeDoctorsProvider).value ?? [];
    final availableAsync = isPatientValid ? ref.watch(availablePackageBalanceProvider(patientId)) : null;
    final proposedCount = _usePackage ? _computedSlots.length : 0;
    final isSubmissionBlocked = isPatientValid && (availableAsync == null || availableAsync.isLoading || availableAsync.hasError || proposedCount > (availableAsync.value ?? 0));

    return LoadingOverlay(
      isLoading: _isSubmitting || _isLoadingDoctors,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookingFormFields(
              patientIdController: _patientIdController, selectedType: _selectedType,
              onTypeChanged: (type) {
                final oldType = _selectedType;
                setState(() => _selectedType = type);
                if (oldType != AppointmentType.checkUp && type == AppointmentType.checkUp) _autoSelectSuperAdmin();
              },
              isRecurring: _isRecurring, onRecurringChanged: (val) => setState(() => _isRecurring = val),
              selectedDate: _selectedDate, onDateChanged: (date) => setState(() => _selectedDate = date),
              selectedTime: _selectedTime, onTimeChanged: (time) => setState(() => _selectedTime = time),
              notesController: _notesController, patientIdValidator: (val) => (val == null || val.trim().length != 36) ? AppStrings.patientRequired : null,
              dateErrorText: _dateErrorText, timeErrorText: _timeErrorText,
            ),
            const SizedBox(height: AppSizes.p16),
            DoctorSelectorDropdown(
              activeDoctors: activeDocs, selectedDoctors: _assignedDoctors, isEnabled: isPatientValid,
              onDoctorSelected: (doc) {
                if (_assignedDoctors.any((d) => d.id == doc.id)) return;
                if (_assignedDoctors.length >= 2) {
                  AppSnackbar.show(context, message: 'Maximum 2 doctors can be assigned', variant: AppSnackbarVariant.error);
                  return;
                }
                setState(() => _assignedDoctors = [..._assignedDoctors, doc]);
              },
            ),
            const SizedBox(height: AppSizes.p16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.usePackageBalance, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                Switch(value: _usePackage, onChanged: (val) => setState(() => _usePackage = val), activeThumbColor: AppColors.primary),
              ],
            ),
            if (_isRecurring) ...[
              const SizedBox(height: AppSizes.p16),
              RecurringPatternPicker(
                selectedWeekdays: _selectedWeekdays, onWeekdaysChanged: (days) => setState(() => _selectedWeekdays = days),
                sessionsController: _sessionsController, sessionsValidator: (val) {
                  if (val == null || val.trim().isEmpty) return AppStrings.sessionsRequired;
                  final count = int.tryParse(val);
                  if (count == null || count <= 0 || count > 24) return 'Enter 1 to 24';
                  return null;
                },
                daysErrorText: _daysErrorText,
              ),
            ],
            if (_assignedDoctors.isNotEmpty) ...[
              const SizedBox(height: AppSizes.p24),
              Text(AppStrings.assignedDoctors, style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSizes.p8),
              SelectedDoctorsChips(doctors: _assignedDoctors, onRemoveDoctor: (doc) => setState(() => _assignedDoctors = _assignedDoctors.where((d) => d.id != doc.id).toList())),
            ],
            if (isPatientValid) ...[
              const SizedBox(height: AppSizes.p24),
              AppointmentBalanceDiagnostics(patientId: patientId, requestedCount: proposedCount),
            ],
            if (_computedSlots.isNotEmpty) ...[
              const SizedBox(height: AppSizes.p24),
              BookingSlotsPreview(slots: _computedSlots, timeOfDay: _selectedTime),
            ],
            const SizedBox(height: AppSizes.p32),
            AppButton(labelText: AppStrings.save, onPressed: isSubmissionBlocked ? null : _submitForm, debounceMs: 1000),
          ],
        ),
      ),
    );
  }
}
