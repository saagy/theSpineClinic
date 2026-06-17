/// Doctor selector that opens a searchable bottom sheet — same pattern
/// as the doctor filter in [UnifiedFilterSheet].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';

class DoctorSelectorDropdown extends ConsumerWidget {
  const DoctorSelectorDropdown({
    super.key,
    required this.selectedDoctors,
    required this.isEnabled,
    required this.onDoctorSelected,
    required this.onDoctorRemoved,
  });

  final List<Staff> selectedDoctors;
  final bool isEnabled;
  final ValueChanged<Staff> onDoctorSelected;
  final ValueChanged<Staff> onDoctorRemoved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Add Doctor', style: AppTextStyles.captionMedium.copyWith(color: AppColors.textSecondary)),
      const SizedBox(height: AppSizes.p6),
      GestureDetector(
        onTap: isEnabled ? () => _openDoctorSheet(context) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p14),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.surface : AppColors.background,
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
            border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
          ),
          child: Row(children: [
            Icon(Icons.person_add_alt_rounded, size: AppSizes.iconDefault,
                color: isEnabled ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: AppSizes.p12),
            Text(isEnabled ? 'Select doctor…' : 'Select patient first',
                style: AppTextStyles.body.copyWith(
                    color: isEnabled ? AppColors.textSecondary : AppColors.textMuted)),
          ]),
        ),
      ),
    ]);
  }

  void _openDoctorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24))),
      builder: (_) => _DoctorSearchSheet(
        selectedDoctors: selectedDoctors,
        onSelected: onDoctorSelected,
        onRemoved: onDoctorRemoved,
      ),
    );
  }
}

/// Self-contained search sheet matching the [UnifiedFilterSheet] doctor pattern.
class _DoctorSearchSheet extends ConsumerStatefulWidget {
  const _DoctorSearchSheet({required this.selectedDoctors, required this.onSelected, required this.onRemoved});
  final List<Staff> selectedDoctors;
  final ValueChanged<Staff> onSelected;
  final ValueChanged<Staff> onRemoved;
  @override
  ConsumerState<_DoctorSearchSheet> createState() => _DoctorSearchSheetState();
}

class _DoctorSearchSheetState extends ConsumerState<_DoctorSearchSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Staff> _filter(List<Staff> docs) {
    if (_query.isEmpty) return docs;
    final q = _query.toLowerCase();
    return docs.where((d) => d.fullName.toLowerCase().contains(q)).toList();
  }

  void _toggle(Staff doctor) {
    if (widget.selectedDoctors.any((d) => d.id == doctor.id)) {
      widget.onRemoved(doctor);
    } else {
      widget.onSelected(doctor);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(activeDoctorsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(0, AppSizes.p16, 0, bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: AppSizes.p16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Text('Select Doctor', style: AppTextStyles.headingSmall),
        ),
        const SizedBox(height: AppSizes.p12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: 'Search doctors…', hintStyle: AppTextStyles.bodySecondary,
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: AppSizes.iconDefault),
              filled: true, fillColor: AppColors.background,
              contentPadding: AppSizes.paddingCell,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.r12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.p12),
        docsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSizes.p24),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (docs) {
            final filtered = _filter(docs);
            if (filtered.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSizes.p24),
                child: Center(child: Text('No doctors found')),
              );
            }
            return Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) {
                  final d = filtered[i];
                  final bool taken = widget.selectedDoctors.any((s) => s.id == d.id);
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(d.fullName.isNotEmpty ? d.fullName[0].toUpperCase() : '?',
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.textOnPrimary)),
                    ),
                    title: Text(d.fullName, style: AppTextStyles.body),
                    trailing: taken ? const Icon(Icons.check_circle, color: AppColors.success, size: AppSizes.iconSmall) : null,
                    onTap: () => _toggle(d),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.p16),
      ]),
    );
  }
}
