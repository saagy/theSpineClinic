import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_filter_doctor_view.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_filter_main_view.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_sort_options.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

class PatientFilterResult {
  const PatientFilterResult({
    required this.clinic,
    required this.doctorId,
    required this.sortOption,
  });

  final ClinicLocation? clinic;
  final String? doctorId;
  final PatientSortOption sortOption;
}

enum _FilterSheetPage { main, doctorPicker }

/// Collapsible filter sheet with internal sub-screen for searchable doctor picker.
class PatientFilterSheet extends ConsumerStatefulWidget {
  const PatientFilterSheet({
    super.key,
    required this.initialClinic,
    required this.initialDoctorId,
    required this.initialSort,
    required this.canFilterDoctor,
  });

  final ClinicLocation? initialClinic;
  final String? initialDoctorId;
  final PatientSortOption initialSort;
  final bool canFilterDoctor;

  static Future<PatientFilterResult?> show({
    required BuildContext context,
    required ClinicLocation? clinic,
    required String? doctorId,
    required PatientSortOption sort,
    required bool canFilterDoctor,
  }) {
    return showModalBottomSheet<PatientFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PatientFilterSheet(
        initialClinic: clinic,
        initialDoctorId: doctorId,
        initialSort: sort,
        canFilterDoctor: canFilterDoctor,
      ),
    );
  }

  @override
  ConsumerState<PatientFilterSheet> createState() => _PatientFilterSheetState();
}

class _PatientFilterSheetState extends ConsumerState<PatientFilterSheet> {
  _FilterSheetPage _page = _FilterSheetPage.main;
  late ClinicLocation? _clinic = widget.initialClinic;
  late String? _doctorId = widget.initialDoctorId;
  late PatientSortOption _sort = widget.initialSort;

  void _reset() {
    setState(() {
      _clinic = null;
      _doctorId = null;
      _sort = PatientSortOption.nameAsc;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      PatientFilterResult(clinic: _clinic, doctorId: _doctorId, sortOption: _sort),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final doctors = widget.canFilterDoctor
        ? (ref.watch(allDoctorsForFilterProvider).value ?? const <Staff>[])
        : const <Staff>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.r16)),
        border: Border.all(color: cs.outlineVariant, width: AppSizes.borderWidth),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _page == _FilterSheetPage.doctorPicker
              ? PatientFilterDoctorView(
                  selectedDoctorId: _doctorId,
                  doctors: doctors,
                  onDoctorSelected: (id) => setState(() {
                    _doctorId = id;
                    _page = _FilterSheetPage.main;
                  }),
                  onBack: () => setState(() => _page = _FilterSheetPage.main),
                )
              : PatientFilterMainView(
                  selectedClinic: _clinic,
                  selectedDoctorId: _doctorId,
                  selectedSort: _sort,
                  canFilterDoctor: widget.canFilterDoctor,
                  doctors: doctors,
                  onClinicChanged: (c) => setState(() => _clinic = c),
                  onOpenDoctorPicker: () => setState(() => _page = _FilterSheetPage.doctorPicker),
                  onSortChanged: (s) => setState(() => _sort = s),
                  onReset: _reset,
                  onApply: _apply,
                ),
        ),
      ),
    );
  }
}
