import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_replacement_args.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_content.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/doctor_replacement_loader.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';
import 'package:spine_clinic_app/shared/widgets/unified_filter_sheet.dart';

/// Screen for bulk reassigning an absent doctor's appointments to a replacement.
class DoctorReplacementScreen extends ConsumerStatefulWidget {
  const DoctorReplacementScreen({
    super.key,
    this.args,
    this.absentDoctorId,
    this.date,
  });

  final DoctorReplacementArgs? args;
  final String? absentDoctorId;
  final DateTime? date;

  @override
  ConsumerState<DoctorReplacementScreen> createState() =>
      _DoctorReplacementScreenState();
}

class _DoctorReplacementScreenState
    extends ConsumerState<DoctorReplacementScreen> {
  Staff? _absentDoctor;
  List<Staff> _availableDoctors = const [];
  List<AppointmentWithPatient> _appointments = const [];
  DateTime _day = DateTime.now();
  final Set<String> _appointmentIds = {};
  Staff? _selectedDoctor;
  bool _loading = true;
  AppException? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.args != null) {
      _initArgs(widget.args!);
    } else {
      Future.microtask(_loadFallback);
    }
  }

  void _initArgs(DoctorReplacementArgs args) {
    _absentDoctor = args.absentDoctor;
    _availableDoctors = args.availableDoctors;
    _appointments = args.appointments;
    _day = args.day;
    _appointmentIds.addAll(args.appointments.map((a) => a.appointment.id));
    _loading = false;
  }

  Future<void> _loadFallback() async {
    setState(() => _loading = true);
    final result = await DoctorReplacementLoader.loadFallback(
      ref: ref,
      doctorId: widget.absentDoctorId,
      date: widget.date,
    );
    if (!mounted) return;
    result.when(
      success: (args) => setState(() => _initArgs(args)),
      failure: (err) => setState(() {
        _loading = false;
        _error = err;
      }),
    );
  }

  Future<void> _chooseDoctors() async {
    String? chosenDoctorId;
    await AppBottomSheet.show<void>(
      context: context,
      title: AppStrings.selectReplacementDoctors,
      builder: (sheetContext, scrollController) => UnifiedFilterSheet(
        initialDoctorId: _selectedDoctor?.id,
        initialClinic: null,
        showBranchFilter: false,
        showActions: false,
        showDeactivated: false,
        excludeDoctorIds: [_absentDoctor?.id ?? ''],
        scrollController: scrollController,
        onApplied: (doctorId, _) {
          chosenDoctorId = doctorId;
          Navigator.of(sheetContext).pop();
        },
      ),
    );
    if (chosenDoctorId == null || !mounted) return;
    final doctor = _availableDoctors
        .where((d) => d.id == chosenDoctorId)
        .firstOrNull;
    if (doctor != null) setState(() => _selectedDoctor = doctor);
  }

  Future<void> _submit() async {
    if (_selectedDoctor == null || _appointmentIds.isEmpty || _absentDoctor == null) return;
    setState(() => _submitting = true);
    final result = await ref
        .read(appointmentRepositoryProvider)
        .bulkReplaceDoctor(
          absentDoctorId: _absentDoctor!.id,
          replacementDoctorIds: [_selectedDoctor!.id],
          appointmentIds: _appointmentIds.toList(),
          day: _day,
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
        context.pop(true);
      },
      failure: (error) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  void _onSelectAll(bool? value) => setState(() {
        if (value ?? false) {
          _appointmentIds.addAll(_appointments.map((a) => a.appointment.id));
        } else {
          _appointmentIds.clear();
        }
      });

  void _onToggle(String id, bool selected) => setState(() {
        if (selected) {
          _appointmentIds.add(id);
        } else {
          _appointmentIds.remove(id);
        }
      });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String title = _absentDoctor != null
        ? AppStrings.replaceDoctorTitle(_absentDoctor!.fullName)
        : AppStrings.replaceDoctor;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(leading: const AppBackButton(), title: Text(title)),
      body: SafeArea(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.p16),
                child: SkeletonTileList(count: 4),
              )
            : _error != null
                ? ErrorView(exception: _error!, onRetry: _loadFallback)
                : _appointments.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_busy_rounded,
                        message: AppStrings.noAppointmentsFound,
                      )
                    : DoctorReplacementContent(
                        day: _day,
                        appointments: _appointments,
                        appointmentIds: _appointmentIds,
                        selectedDoctor: _selectedDoctor,
                        isSubmitting: _submitting,
                        onChooseDoctor: _chooseDoctors,
                        onSelectAllChanged: _onSelectAll,
                        onToggleAppointment: _onToggle,
                        onSubmit: _submit,
                      ),
      ),
    );
  }
}
