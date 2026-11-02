import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/filter_sheet_frame.dart';
import 'package:spine_clinic_app/shared/widgets/filter_doctor_field.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/shared/widgets/filter_doctor_view.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

class ScheduleFilterResult {
  const ScheduleFilterResult({required this.doctorId});
  final String? doctorId;
}

enum _ScheduleFilterPage { main, doctorPicker }

/// Modal filter sheet for the appointments schedule tab,
/// following the design language of [PatientFilterSheet].
class ScheduleFilterSheet extends ConsumerStatefulWidget {
  const ScheduleFilterSheet({super.key, required this.initialDoctorId});

  final String? initialDoctorId;

  static Future<ScheduleFilterResult?> show({
    required BuildContext context,
    required String? doctorId,
  }) {
    return FilterSheetFrame.show<ScheduleFilterResult>(
      context: context,
      builder: (ctx) => ScheduleFilterSheet(initialDoctorId: doctorId),
    );
  }

  @override
  ConsumerState<ScheduleFilterSheet> createState() => _ScheduleFilterSheetState();
}

class _ScheduleFilterSheetState extends ConsumerState<ScheduleFilterSheet> {
  _ScheduleFilterPage _page = _ScheduleFilterPage.main;
  late String? _doctorId = widget.initialDoctorId;

  void _reset() {
    setState(() => _doctorId = null);
  }

  void _apply() {
    Navigator.of(context).pop(ScheduleFilterResult(doctorId: _doctorId));
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(allDoctorsForFilterProvider).value ?? const <Staff>[];

    return FilterSheetFrame(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _page == _ScheduleFilterPage.doctorPicker
            ? FilterDoctorView(
                selectedDoctorId: _doctorId,
                doctors: doctors,
                onDoctorSelected: (id) => setState(() {
                  _doctorId = id;
                  _page = _ScheduleFilterPage.main;
                }),
                onBack: () => setState(() => _page = _ScheduleFilterPage.main),
              )
            : FilterSheetBody(
                onReset: _reset,
                onApply: _apply,
                children: [
                  const FilterSectionTitle(AppStrings.assignedDoctors),
                  FilterDoctorField(
                    selectedDoctorId: _doctorId,
                    doctors: doctors,
                    onTap: () => setState(() => _page = _ScheduleFilterPage.doctorPicker),
                  ),
                  const SizedBox(height: AppSizes.p20),
                ],
              ),
      ),
    );
  }
}
