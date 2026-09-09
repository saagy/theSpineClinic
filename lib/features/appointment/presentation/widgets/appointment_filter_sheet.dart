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

part 'appointment_filter_sheet_state.dart';

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
    this.appointmentFiltersBuilder,
    this.showAppointmentFilters = true,
    this.onResetAdditional,
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
  final WidgetBuilder? appointmentFiltersBuilder;
  final bool showAppointmentFilters;
  final VoidCallback? onResetAdditional;

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
    WidgetBuilder? appointmentFiltersBuilder,
    bool showAppointmentFilters = true,
    VoidCallback? onResetAdditional,
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
        appointmentFiltersBuilder: appointmentFiltersBuilder,
        showAppointmentFilters: showAppointmentFilters,
        onResetAdditional: onResetAdditional,
      ),
    );
  }

  @override
  ConsumerState<AppointmentFilterSheet> createState() => _AppointmentFilterSheetState();
}
