/// New-appointment form state and lifecycle.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_balance_diagnostics.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_form_fields.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_slots_preview.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/booking_submit_helper.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/date_recurrence_utils.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/patient_search_sheet.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/recurrence_guide.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/recurring_pattern_picker.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/app_doctor_multi_select_field.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/loading_overlay.dart';

part 'new_appointment_form_actions.dart';
part 'new_appointment_form_view.dart';
part 'new_appointment_provider_section.dart';
part 'new_appointment_recurrence_section.dart';

class NewAppointmentForm extends ConsumerStatefulWidget {
  const NewAppointmentForm({
    super.key,
    this.preselectedPatientId,
    this.preselectedDate,
    this.preselectedDoctorId,
    this.expectedNextVisitDate,
  });

  final String? preselectedPatientId;
  final DateTime? preselectedDate;
  final String? preselectedDoctorId;
  final DateTime? expectedNextVisitDate;

  @override
  ConsumerState<NewAppointmentForm> createState() => _NewAppointmentFormState();
}

class _NewAppointmentFormState extends ConsumerState<NewAppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _doctorFieldKey = GlobalKey<FormFieldState<List<Staff>>>();
  late final TextEditingController _sessionsController;
  AppointmentType _selectedType = AppointmentType.normalPtSession;
  bool _isRecurring = false;
  bool _isSubmitting = false;
  bool _usePackage = true;
  bool _isFetchingDoctors = false;
  bool _doctorFieldEnabled = true;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  Set<int> _selectedWeekdays = <int>{};
  String? _dateErrorText;
  String? _timeErrorText;
  String? _daysErrorText;
  String? _patientId;

  // Bundling state variables
  bool _bundleSecondarySession = false;
  AppointmentType _secondaryType = AppointmentType.normalPtSession;
  final _secondaryDoctorFieldKey = GlobalKey<FormFieldState<List<Staff>>>();
  TimeOfDay? _secondaryTime = const TimeOfDay(hour: 9, minute: 0);
  String? _secondaryTimeErrorText;
  bool _secondaryUsePackage = true;
  List<Staff> _assignedDoctorsCache = const [];

  static const Duration _fetchTimeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _sessionsController = TextEditingController();
    _selectedDate = widget.preselectedDate ?? DateTime.now();
    final String? patientId = widget.preselectedPatientId?.trim();
    if (patientId != null && patientId.length == 36) {
      _patientId = patientId;
      _doctorFieldEnabled = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fetchAssignedDoctors(),
      );
    }
  }

  @override
  void dispose() {
    _sessionsController.dispose();
    super.dispose();
  }

  void _mutate(VoidCallback mutation) => setState(mutation);

  @override
  Widget build(BuildContext context) => _buildForm(context);
}
