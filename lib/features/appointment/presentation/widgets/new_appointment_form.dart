/// Modern new-appointment form with patient selector, pill chips,
/// searchable doctor sheet, and receipt-style ledger.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import 'package:spine_clinic_app/features/appointment/presentation/widgets/selected_doctors_chips.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_balance_diagnostics.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_selector_dropdown.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_list_providers.dart';
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
  late final TextEditingController _sessionsController;
  AppointmentType _selectedType = AppointmentType.session;
  bool _isRecurring = false, _isLoadingDoctors = false, _isSubmitting = false, _usePackage = true;
  DateTime? _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  Set<int> _selectedWeekdays = <int>{};
  List<Staff> _assignedDoctors = <Staff>[];
  String? _dateErrorText, _timeErrorText, _daysErrorText;
  String? _patientId;

  @override
  void initState() {
    super.initState();
    _sessionsController = TextEditingController();
    if (widget.preselectedPatientId != null && widget.preselectedPatientId!.trim().length == 36) {
      _patientId = widget.preselectedPatientId!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDoctors());
    }
  }

  @override
  void dispose() {
    _sessionsController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    if (_patientId == null) return;
    setState(() => _isLoadingDoctors = true);
    final result = await ref.read(appointmentRepositoryProvider).getAssignedDoctors(_patientId!);
    if (!mounted) return;
    result.when(
      success: (docs) => setState(() {
        _assignedDoctors = docs.where((s) => s.isActive).toList();
        _isLoadingDoctors = false;
        if (_selectedType == AppointmentType.checkUp) _autoSelectSuperAdmin();
      }),
      failure: (e) {
        setState(() => _isLoadingDoctors = false);
        AppSnackbar.show(context, message: AppStrings.fromKey(e.userMessageKey),
            variant: AppSnackbarVariant.error);
      },
    );
  }

  void _onPatientSelected(Patient patient) {
    setState(() => _patientId = patient.id);
    _fetchDoctors();
  }

  void _autoSelectSuperAdmin() {
    final docs = ref.read(activeDoctorsProvider).value ?? [];
    try {
      final admin = docs.firstWhere((d) => d.role == UserRole.superAdmin);
      setState(() => _assignedDoctors = [admin]);
    } catch (_) {}
  }

  List<DateTime> get _computedSlots => _selectedDate == null ? const [] :
      (!_isRecurring ? [_selectedDate!] : DateRecurrenceUtils.generateRecurrenceSlots(
          startDate: _selectedDate!, weekdays: _selectedWeekdays,
          totalSessions: int.tryParse(_sessionsController.text) ?? 0));

  Future<void> _submitForm() async {
    setState(() {
      _dateErrorText = _selectedDate == null ? 'Date required' : null;
      _timeErrorText = _selectedTime == null ? 'Time required' : null;
      _daysErrorText = _isRecurring && _selectedWeekdays.isEmpty ? 'Select at least one day' : null;
    });
    if (_dateErrorText != null || _timeErrorText != null || _daysErrorText != null) return;
    if (_patientId == null) {
      AppSnackbar.show(context, message: 'Please select a patient', variant: AppSnackbarVariant.error);
      return;
    }
    if (_assignedDoctors.isEmpty) {
      AppSnackbar.show(context, message: AppStrings.noAssignedDoctors, variant: AppSnackbarVariant.error);
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await BookingSubmitHelper.executeBooking(
      repo: ref.read(appointmentRepositoryProvider),
      patientId: _patientId!, type: _selectedType, slots: _computedSlots, time: _selectedTime!,
      creatorId: ref.read(currentUserProvider).value?.id, doctors: _assignedDoctors, usePackage: _usePackage,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.when(
      success: (_) {
        ref.invalidate(todayAppointmentsProvider);
        ref.invalidate(patientAppointmentsProvider(_patientId!));
        ref.invalidate(patientDetailProvider(_patientId!));
        ref.invalidate(futureScheduledAppointmentsCountProvider(_patientId!));
        ref.invalidate(availablePackageBalanceProvider(_patientId!));
        AppSnackbar.show(context, message: _isRecurring ? 'Recurring sessions booked' : 'Appointment booked',
            variant: AppSnackbarVariant.success);
        context.pop();
      },
      failure: (_) => AppSnackbar.show(context, message: 'Booking failed. Try again.',
          variant: AppSnackbarVariant.error),
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
    final availableAsync = isPatientValid ? ref.watch(availablePackageBalanceProvider(_patientId!)) : null;
    final proposedCount = _usePackage ? _computedSlots.length : 0;
    final isSubmissionBlocked = isPatientValid &&
        (availableAsync == null || availableAsync.isLoading || availableAsync.hasError ||
         proposedCount > (availableAsync.value ?? 0));

    return LoadingOverlay(
      isLoading: _isSubmitting || _isLoadingDoctors,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            BookingFormFields(
              preselectedPatient: patient,
              onPatientTap: () => _openPatientSearch(context),
              selectedType: _selectedType,
              onTypeChanged: (type) {
                final old = _selectedType;
                setState(() => _selectedType = type);
                if (old != AppointmentType.checkUp && type == AppointmentType.checkUp) _autoSelectSuperAdmin();
              },
              isRecurring: _isRecurring,
              onRecurringChanged: (v) => setState(() => _isRecurring = v),
              selectedDate: _selectedDate,
              onDateChanged: (d) => setState(() => _selectedDate = d),
              selectedTime: _selectedTime,
              onTimeChanged: (t) => setState(() => _selectedTime = t),
              dateErrorText: _dateErrorText,
              timeErrorText: _timeErrorText,
            ),
            // ── Recurring section (right after date/time) ──
            if (_isRecurring) ...[
              const SizedBox(height: AppSizes.p16),
              if (_selectedDate != null && _selectedWeekdays.isNotEmpty)
                _RecurrenceGuide(startDate: _selectedDate!, selectedWeekdays: _selectedWeekdays,
                    totalSessions: int.tryParse(_sessionsController.text) ?? 0, slots: _computedSlots),
              RecurringPatternPicker(
                selectedWeekdays: _selectedWeekdays,
                onWeekdaysChanged: (d) => setState(() => _selectedWeekdays = d),
                sessionsController: _sessionsController,
                daysErrorText: _daysErrorText,
              ),
            ],
            const SizedBox(height: AppSizes.p16),
            // ── Doctor selector ──
            DoctorSelectorDropdown(
              selectedDoctors: _assignedDoctors,
              isEnabled: isPatientValid,
              onDoctorSelected: (doc) {
                if (_assignedDoctors.any((d) => d.id == doc.id)) return;
                setState(() => _assignedDoctors = [..._assignedDoctors, doc]);
              },
              onDoctorRemoved: (doc) {
                setState(() => _assignedDoctors = _assignedDoctors.where((d) => d.id != doc.id).toList());
              },
            ),
            const SizedBox(height: AppSizes.p16),
            // ── Use package toggle ──
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(AppStrings.usePackageBalance,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
              Switch(value: _usePackage, onChanged: (v) => setState(() => _usePackage = v),
                  activeThumbColor: AppColors.primary),
            ]),
            if (_assignedDoctors.isNotEmpty) ...[
              const SizedBox(height: AppSizes.p16),
              SelectedDoctorsChips(doctors: _assignedDoctors,
                  onRemoveDoctor: (doc) => setState(() => _assignedDoctors = _assignedDoctors.where((d) => d.id != doc.id).toList())),
            ],
            if (isPatientValid) ...[
              const SizedBox(height: AppSizes.p24),
              AppointmentBalanceDiagnostics(patientId: _patientId!, requestedCount: proposedCount),
            ],
            if (_computedSlots.isNotEmpty) ...[
              const SizedBox(height: AppSizes.p24),
              BookingSlotsPreview(slots: _computedSlots, timeOfDay: _selectedTime, usePackage: _usePackage),
            ],
            const SizedBox(height: AppSizes.p32),
            AppButton(labelText: AppStrings.save,
                onPressed: (isSubmissionBlocked || _isSubmitting) ? null : _submitForm,
                isLoading: _isSubmitting, debounceMs: 1000),
            const SizedBox(height: AppSizes.p48),
          ]),
        ),
      ),
    );
  }

  void _openPatientSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24))),
      builder: (ctx) => _PatientSearchSheet(
        onSelected: (p) {
          _onPatientSelected(p);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

/// Patient search bottom sheet — reusable for global booking.
class _PatientSearchSheet extends ConsumerStatefulWidget {
  const _PatientSearchSheet({required this.onSelected});
  final ValueChanged<Patient> onSelected;
  @override
  ConsumerState<_PatientSearchSheet> createState() => _PatientSearchSheetState();
}

class _PatientSearchSheetState extends ConsumerState<_PatientSearchSheet> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(patientListProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Column(children: [
        const SizedBox(height: AppSizes.p12),
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Select Patient', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSizes.p12),
            TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _q = v),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: 'Search by name or phone…', hintStyle: AppTextStyles.bodySecondary,
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: AppSizes.iconDefault),
                filled: true, fillColor: AppColors.background,
                contentPadding: AppSizes.paddingCell,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.r12), borderSide: BorderSide.none),
              ),
            ),
          ]),
        ),
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => const Center(child: Text('Error loading patients')),
            data: (patients) {
              final filtered = _q.isEmpty ? patients
                  : patients.where((p) => p.fullName.toLowerCase().contains(_q.toLowerCase()) ||
                      p.phoneNumber.contains(_q)).toList();
              if (filtered.isEmpty) return const Center(child: Text('No patients found'));
              return ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.primary, radius: 18,
                        child: Text(p.fullName[0].toUpperCase(), style: AppTextStyles.captionBold.copyWith(color: AppColors.textOnPrimary))),
                    title: Text(p.fullName, style: AppTextStyles.bodyBold),
                    subtitle: Text(p.phoneNumber, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    onTap: () => widget.onSelected(p),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Clean guidance chip for recurring bookings.
class _RecurrenceGuide extends StatelessWidget {
  const _RecurrenceGuide({required this.startDate, required this.selectedWeekdays, required this.totalSessions, required this.slots});
  final DateTime startDate; final Set<int> selectedWeekdays; final int totalSessions; final List<DateTime> slots;

  static const List<String> _dayLabels = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

  @override
  Widget build(BuildContext context) {
    final first = slots.isNotEmpty ? DateFormat('MMM d').format(slots.first) : '—';
    final cnt = totalSessions > 0 ? '$totalSessions session${totalSessions == 1 ? '' : 's'}' : '… sessions';
    final days = selectedWeekdays.map((d) => _dayLabels[d - 1]).join(', ');
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSizes.p12, AppSizes.p8, AppSizes.p12, AppSizes.p8),
      margin: const EdgeInsets.only(bottom: AppSizes.p12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
      ),
      child: RichText(text: TextSpan(
        style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
        children: [
          TextSpan(text: cnt, style: AppTextStyles.captionBold.copyWith(color: cs.primary)),
          const TextSpan(text: ' starting '),
          TextSpan(text: first, style: const TextStyle(fontWeight: FontWeight.w600)),
          const TextSpan(text: ' on '),
          TextSpan(text: days, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      )),
    );
  }
}
