import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/doctor_search_tile.dart';

class DoctorSearchSheet extends StatefulWidget {
  const DoctorSearchSheet({
    super.key,
    required this.activeDoctors,
    required this.selectedDoctors,
    required this.onSelectionChanged,
  });

  final List<Staff> activeDoctors;
  final List<Staff> selectedDoctors;
  final ValueChanged<List<Staff>> onSelectionChanged;

  @override
  State<DoctorSearchSheet> createState() => _DoctorSearchSheetState();
}

class _DoctorSearchSheetState extends State<DoctorSearchSheet> {
  late final Set<String> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedDoctors.map((doctor) => doctor.id).toSet();
  }

  void _toggle(Staff doctor) {
    final bool selected = _selectedIds.contains(doctor.id);
    if (selected && _selectedIds.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.atLeastOneDoctorRequired)),
      );
      return;
    }
    setState(() {
      if (selected) {
        _selectedIds.remove(doctor.id);
      } else {
        _selectedIds.add(doctor.id);
      }
    });
    final List<Staff> updated = [
      for (final Staff doctor in widget.activeDoctors)
        if (_selectedIds.contains(doctor.id)) doctor,
    ];
    final Set<String> activeIds = widget.activeDoctors
        .map((doctor) => doctor.id)
        .toSet();
    updated.addAll(
      widget.selectedDoctors.where((doctor) => !activeIds.contains(doctor.id)),
    );
    widget.onSelectionChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final String query = _query.trim().toLowerCase();
    final List<Staff> doctors =
        widget.activeDoctors
            .where(
              (doctor) =>
                  query.isEmpty ||
                  doctor.fullName.toLowerCase().contains(query),
            )
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * AppSizes.sheetInitialLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p20,
                0,
                AppSizes.p20,
                AppSizes.p12,
              ),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: AppStrings.searchDoctors,
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: doctors.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.noMatchingDoctorsFound,
                        style: AppTextStyles.bodySecondary,
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: doctors.length,
                      itemBuilder: (_, index) {
                        final Staff doctor = doctors[index];
                        return DoctorSearchTile(
                          doctor: doctor,
                          isSelected: _selectedIds.contains(doctor.id),
                          onTap: () => _toggle(doctor),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
