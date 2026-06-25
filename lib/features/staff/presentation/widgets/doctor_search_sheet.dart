import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/doctor_search_tile.dart';


/// Bottom sheet content for searching and multi-selecting doctors.
///
/// Owns its `_selectedIds` state (B1/B2/B3 fix): the modal mirrors its
/// selection to the parent through [onSelectionChanged] on every toggle.
/// This keeps taps cumulative and re-renders the check icons immediately,
/// regardless of whether the parent's `FormField` state re-emits.
class DoctorSearchSheet extends StatefulWidget {
  const DoctorSearchSheet({
    super.key,
    required this.activeDoctors,
    required this.selectedDoctors,
    required this.onSelectionChanged,
  });

  final List<Staff> activeDoctors;
  final List<Staff> selectedDoctors;
  final void Function(List<Staff> updated) onSelectionChanged;

  @override
  State<DoctorSearchSheet> createState() => _DoctorSearchSheetState();
}

class _DoctorSearchSheetState extends State<DoctorSearchSheet> {
  late Set<String> _selectedIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.selectedDoctors.map((s) => s.id).toSet();
  }

  @override
  void didUpdateWidget(covariant DoctorSearchSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.selectedDoctors.map((s) => s.id).toSet();
    if (!_sameSet(incoming, _selectedIds)) {
      setState(() {
        _selectedIds
          ..clear()
          ..addAll(incoming);
      });
    }
  }

  void _toggle(Staff doctor) {
    final isSelected = _selectedIds.contains(doctor.id);
    if (isSelected && _selectedIds.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.atLeastOneDoctorRequired),
        ),
      );
      return;
    }
    setState(() {
      if (isSelected) {
        _selectedIds.remove(doctor.id);
      } else {
        _selectedIds.add(doctor.id);
      }
    });
    _emit();
  }

  void _emit() {
    final updated = <Staff>[
      for (final d in widget.activeDoctors)
        if (_selectedIds.contains(d.id)) d,
    ];
    // Preserve any originally-selected deactivated doctors — they can't be
    // toggled in this sheet but can be removed via the × button in the form.
    final activeIds = widget.activeDoctors.map((d) => d.id).toSet();
    for (final d in widget.selectedDoctors) {
      if (!activeIds.contains(d.id)) {
        updated.add(d);
      }
    }
    widget.onSelectionChanged(updated);
  }

  List<Staff> _filtered() {
    final q = _query.toLowerCase();
    final filtered = q.isEmpty
        ? List<Staff>.from(widget.activeDoctors)
        : widget.activeDoctors
            .where((d) => d.fullName.toLowerCase().contains(q))
            .toList();
    filtered.sort((a, b) =>
        a.isActive == b.isActive ? a.fullName.compareTo(b.fullName) : (a.isActive ? -1 : 1));
    return filtered;
  }

  bool _sameSet(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final filtered = _filtered();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, AppSizes.p16, 0, bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child:
                Text(AppStrings.selectDoctors, style: AppTextStyles.headingSmall),
          ),
          const SizedBox(height: AppSizes.p12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: AppStrings.searchDoctorsHint,
                hintStyle: AppTextStyles.bodySecondary,
                prefixIcon: Icon(Icons.search_rounded,
                    color: colorScheme.primary, size: AppSizes.iconDefault),
                filled: true,
                fillColor: colorScheme.surface,
                contentPadding: AppSizes.paddingCell,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSizes.p24),
                    child: Text(AppStrings.noMatchingDoctorsFound,
                        style: AppTextStyles.bodySecondary),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final d = filtered[i];
                      return DoctorSearchTile(
                        doctor: d,
                        isSelected: _selectedIds.contains(d.id),
                        onTap: () => _toggle(d),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
