/// Collapsible filter sheet with doctor picker and merged sort options.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_doctor_view.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_main_view.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_sort_options.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

/// Filter selection result returned when the sheet is applied.
class AppointmentFilterResult {
  const AppointmentFilterResult({
    required this.dateFrom,
    required this.dateTo,
    required this.doctorId,
    required this.clinic,
    required this.status,
    required this.type,
    required this.sortOption,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? doctorId;
  final ClinicLocation? clinic;
  final AppointmentStatus? status;
  final AppointmentType? type;
  final AppointmentSortOption sortOption;
}

enum _FilterSheetPage { main, doctorPicker }

/// Bottom sheet modal hosting filters, doctor picker, and sort order.
class AppointmentFilterSheet extends ConsumerStatefulWidget {
  const AppointmentFilterSheet({
    super.key,
    required this.initialDateFrom,
    required this.initialDateTo,
    required this.initialDoctorId,
    required this.initialClinic,
    required this.initialStatus,
    required this.initialType,
    required this.initialSort,
    required this.canFilterDoctor,
    required this.canFilterClinic,
  });

  final DateTime? initialDateFrom;
  final DateTime? initialDateTo;
  final String? initialDoctorId;
  final ClinicLocation? initialClinic;
  final AppointmentStatus? initialStatus;
  final AppointmentType? initialType;
  final AppointmentSortOption initialSort;
  final bool canFilterDoctor;
  final bool canFilterClinic;

  static Future<AppointmentFilterResult?> show({
    required BuildContext context,
    required DateTime? dateFrom,
    required DateTime? dateTo,
    required String? doctorId,
    required ClinicLocation? clinic,
    required AppointmentStatus? status,
    required AppointmentType? type,
    required AppointmentSortOption sort,
    required bool canFilterDoctor,
    required bool canFilterClinic,
  }) {
    return showModalBottomSheet<AppointmentFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppointmentFilterSheet(
        initialDateFrom: dateFrom,
        initialDateTo: dateTo,
        initialDoctorId: doctorId,
        initialClinic: clinic,
        initialStatus: status,
        initialType: type,
        initialSort: sort,
        canFilterDoctor: canFilterDoctor,
        canFilterClinic: canFilterClinic,
      ),
    );
  }

  @override
  ConsumerState<AppointmentFilterSheet> createState() =>
      _AppointmentFilterSheetState();
}

class _AppointmentFilterSheetState
    extends ConsumerState<AppointmentFilterSheet> {
  _FilterSheetPage _page = _FilterSheetPage.main;
  late DateTime? _dateFrom = widget.initialDateFrom;
  late DateTime? _dateTo = widget.initialDateTo;
  late String? _doctorId = widget.initialDoctorId;
  late ClinicLocation? _clinic = widget.initialClinic;
  late AppointmentStatus? _status = widget.initialStatus;
  late AppointmentType? _type = widget.initialType;
  late AppointmentSortOption _sort = widget.initialSort;

  void _reset() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
      _doctorId = null;
      _clinic = null;
      _status = null;
      _type = null;
      _sort = AppointmentSortOption.dateDesc;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      AppointmentFilterResult(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        doctorId: _doctorId,
        clinic: _clinic,
        status: _status,
        type: _type,
        sortOption: _sort,
      ),
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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.r16),
        ),
        border: Border.all(
          color: cs.outlineVariant,
          width: AppSizes.borderWidth,
        ),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _page == _FilterSheetPage.doctorPicker
              ? AppointmentFilterDoctorView(
                  selectedDoctorId: _doctorId,
                  doctors: doctors,
                  onDoctorSelected: (id) => setState(() {
                    _doctorId = id;
                    _page = _FilterSheetPage.main;
                  }),
                  onBack: () => setState(() => _page = _FilterSheetPage.main),
                )
              : AppointmentFilterMainView(
                  selectedDateFrom: _dateFrom,
                  selectedDateTo: _dateTo,
                  selectedDoctorId: _doctorId,
                  selectedClinic: _clinic,
                  selectedStatus: _status,
                  selectedType: _type,
                  selectedSort: _sort,
                  canFilterDoctor: widget.canFilterDoctor,
                  canFilterClinic: widget.canFilterClinic,
                  doctors: doctors,
                  onDateRangeChanged: (from, to) => setState(() {
                    _dateFrom = from;
                    _dateTo = to;
                  }),
                  onOpenDoctorPicker: () =>
                      setState(() => _page = _FilterSheetPage.doctorPicker),
                  onClinicChanged: (c) => setState(() => _clinic = c),
                  onStatusChanged: (s) => setState(() => _status = s),
                  onTypeChanged: (t) => setState(() => _type = t),
                  onSortChanged: (s) => setState(() => _sort = s),
                  onReset: _reset,
                  onApply: _apply,
                ),
        ),
      ),
    );
  }
}
