import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/result.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/bulk_doctor_replacement_result.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_appointment_row.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

class DoctorReplacementModal extends StatefulWidget {
  const DoctorReplacementModal({
    super.key,
    required this.absentDoctor,
    required this.availableDoctors,
    required this.appointments,
    required this.day,
    required this.onSubmit,
  });

  final Staff absentDoctor;
  final List<Staff> availableDoctors;
  final List<AppointmentWithPatient> appointments;
  final DateTime day;
  final Future<Result<BulkDoctorReplacementResult>> Function(
    List<String> doctorIds,
    List<String> appointmentIds,
  )
  onSubmit;

  @override
  State<DoctorReplacementModal> createState() => _DoctorReplacementModalState();
}

class _DoctorReplacementModalState extends State<DoctorReplacementModal> {
  late final Set<String> _appointmentIds;
  List<Staff> _doctors = const [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _appointmentIds = widget.appointments
        .map((item) => item.appointment.id)
        .toSet();
  }

  Future<void> _chooseDoctors() async {
    String? chosenDoctorId;
    await AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.selectReplacementDoctors,
      builder: (sheetContext, scrollController) => UnifiedFilterSheet(
        initialDoctorId: _doctors.firstOrNull?.id,
        initialClinic: null,
        showBranchFilter: false,
        showActions: false,
        showDeactivated: false,
        excludeDoctorIds: [widget.absentDoctor.id],
        scrollController: scrollController,
        onApplied: (doctorId, _) {
          chosenDoctorId = doctorId;
          Navigator.of(sheetContext).pop();
        },
      ),
    );

    if (chosenDoctorId == null || !mounted) return;

    if (chosenDoctorId == widget.absentDoctor.id) {
      AppSnackbar.show(
        context,
        message: AppStrings.cannotReplaceWithSelf,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    final Staff? replacementDoctor = widget.availableDoctors.cast<Staff?>().firstWhere(
          (d) => d?.id == chosenDoctorId,
          orElse: () => null,
        );

    if (replacementDoctor != null) {
      setState(() {
        _doctors = [replacementDoctor];
      });
    }
  }

  Future<void> _submit() async {
    if (_doctors.isEmpty || _appointmentIds.isEmpty) return;
    setState(() => _submitting = true);
    final result = await widget.onSubmit(
      _doctors.map((doctor) => doctor.id).toList(),
      _appointmentIds.toList(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (value) {
        AppSnackbar.show(
          context,
          message: AppStrings.replacementSucceeded(
            value.replacedCount,
            value.remainingCount,
          ),
          variant: AppSnackbarVariant.success,
        );
        Navigator.pop(context, true);
      },
      failure: (error) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool allSelected =
        _appointmentIds.length == widget.appointments.length;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          AppStrings.replaceDoctorTitle(widget.absentDoctor.fullName),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.replacementSummary(
                      DateFormat('EEE, MMM d').format(widget.day),
                      widget.appointments.length,
                    ),
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: AppSizes.p16),
                  OutlinedButton.icon(
                    onPressed: _chooseDoctors,
                    icon: const Icon(Icons.medical_services_outlined),
                    label: Text(
                      _doctors.isEmpty
                          ? AppStrings.selectReplacementDoctors
                          : _doctors.first.fullName,
                    ),
                  ),
                  const SizedBox(height: AppSizes.p16),
                  Row(
                    children: [
                      Checkbox(
                        value: allSelected,
                        onChanged: (value) => setState(() {
                          if (value ?? false) {
                            _appointmentIds.addAll(
                              widget.appointments.map(
                                (item) => item.appointment.id,
                              ),
                            );
                          } else {
                            _appointmentIds.clear();
                          }
                        }),
                      ),
                      Text(AppStrings.selectAll, style: AppTextStyles.bodyBold),
                      const Spacer(),
                      Text(
                        AppStrings.sectionCount(
                          AppStrings.affectedAppointments,
                          _appointmentIds.length,
                        ),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                itemCount: widget.appointments.length,
                itemBuilder: (_, index) {
                  final item = widget.appointments[index];
                  return DoctorReplacementAppointmentRow(
                    item: item,
                    selected: _appointmentIds.contains(item.appointment.id),
                    onChanged: (selected) => setState(() {
                      if (selected) {
                        _appointmentIds.add(item.appointment.id);
                      } else {
                        _appointmentIds.remove(item.appointment.id);
                      }
                    }),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: AppButton(
                labelText: AppStrings.replaceOnAppointments(
                  _appointmentIds.length,
                ),
                isLoading: _submitting,
                onPressed: _doctors.isEmpty || _appointmentIds.isEmpty
                    ? null
                    : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
