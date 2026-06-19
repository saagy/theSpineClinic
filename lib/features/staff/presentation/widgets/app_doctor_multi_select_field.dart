import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Reusable searchable custom form field for doctor multi-selection.
///
/// Tapping the search field opens a bottom sheet with a searchable doctor
/// list. Selected doctors display as avatar+name rows with a remove action.
class AppDoctorMultiSelectField extends FormField<List<Staff>> {
  AppDoctorMultiSelectField({
    super.key,
    required List<Staff> initialValue,
    required void Function(List<Staff>)? onSavedDoctors,
    ValueChanged<List<Staff>>? onChanged,
    super.validator,
  }) : super(
          initialValue: initialValue,
          onSaved: onSavedDoctors == null ? null : (val) => onSavedDoctors(val ?? []),
          builder: (FormFieldState<List<Staff>> state) {
            return _AppDoctorMultiSelectFieldWidget(
              state: state,
              onChanged: onChanged,
            );
          },
        );
}

class _AppDoctorMultiSelectFieldWidget extends ConsumerStatefulWidget {
  const _AppDoctorMultiSelectFieldWidget({
    required this.state,
    this.onChanged,
  });
  final FormFieldState<List<Staff>> state;
  final ValueChanged<List<Staff>>? onChanged;

  @override
  ConsumerState<_AppDoctorMultiSelectFieldWidget> createState() =>
      _AppDoctorMultiSelectFieldWidgetState();
}

class _AppDoctorMultiSelectFieldWidgetState
    extends ConsumerState<_AppDoctorMultiSelectFieldWidget> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _openDoctorSheet(List<Staff> activeDoctors) {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final selected = widget.state.value ?? [];
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;

          return Padding(
            padding: EdgeInsets.fromLTRB(0, AppSizes.p16, 0, bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.p16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                  child: Text('Select Doctors', style: AppTextStyles.headingSmall),
                ),
                const SizedBox(height: AppSizes.p12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
                  child: TextField(
                    autofocus: true,
                    onChanged: (v) => setSheetState(() => query = v),
                    style: AppTextStyles.body,
                    decoration: InputDecoration(
                      hintText: 'Search doctors…',
                      hintStyle: AppTextStyles.bodySecondary,
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.primary, size: AppSizes.iconDefault),
                      filled: true,
                      fillColor: AppColors.background,
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
                  child: _buildDoctorList(
                    docs: activeDoctors,
                    query: query,
                    selected: selected,
                    ctx: ctx,
                    setSheetState: setSheetState,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.state.value ?? [];
    final doctorsAsync = ref.watch(activeDoctorsProvider);
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: BorderSide(
        color: widget.state.hasError ? AppColors.error : AppColors.border,
        width: AppSizes.borderWidth,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          readOnly: true,
          onTap: () {
            final docs = doctorsAsync.value ?? [];
            _openDoctorSheet(docs);
          },
          decoration: InputDecoration(
            isDense: true,
            labelText: 'Search & Assign Doctors',
            hintText: 'Type doctor name...',
            suffixIcon: const Icon(Icons.search_rounded),
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.borderStrong,
                width: AppSizes.borderWidthFocused,
              ),
            ),
          ),
        ),
        if (selected.isNotEmpty) ...[
          const SizedBox(height: AppSizes.p12),
          Column(
            children: selected.map((doctor) => _buildDoctorRow(doctor)).toList(),
          ),
        ],
        if (widget.state.hasError) ...[
          const SizedBox(height: AppSizes.p6),
          Text(
            widget.state.errorText ?? '',
            style: AppTextStyles.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildDoctorList({
    required List<Staff> docs,
    required String query,
    required List<Staff> selected,
    required BuildContext ctx,
    required StateSetter setSheetState,
  }) {
    final filtered = query.isEmpty
        ? docs
        : docs.where((d) =>
            d.fullName.toLowerCase().contains(query.toLowerCase())).toList();
    // Active doctors first, deactivated at the end.
    filtered.sort((a, b) {
      if (a.isActive == b.isActive) return a.fullName.compareTo(b.fullName);
      return a.isActive ? -1 : 1;
    });

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Text(AppStrings.noMatchingDoctorsFound,
            style: AppTextStyles.bodySecondary),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final d = filtered[i];
        final isSel = selected.any((s) => s.id == d.id);
        final initials = d.fullName.isNotEmpty
            ? d.fullName[0].toUpperCase()
            : '?';
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: d.isActive ? AppColors.primary : AppColors.textMuted,
            child: Text(initials,
                style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.textOnPrimary)),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(d.fullName, style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis),
              ),
              if (!d.isActive) ...[
                const SizedBox(width: AppSizes.p6),
                Text(AppStrings.deactivated,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          subtitle: Text(d.email, style: AppTextStyles.caption),
          trailing: isSel
              ? const Icon(Icons.check_circle,
                  color: AppColors.primary, size: AppSizes.iconDefault)
              : const Icon(Icons.circle_outlined,
                  color: AppColors.textMuted, size: AppSizes.iconDefault),
          onTap: () {
            final current = List<Staff>.from(selected);
            if (isSel) {
              if (current.length <= 1) {
                AppSnackbar.show(
                  ctx,
                  message: 'A patient must have at least one assigned doctor.',
                  variant: AppSnackbarVariant.error,
                );
                return;
              }
              current.removeWhere((s) => s.id == d.id);
            } else {
              current.add(d);
            }
            widget.state.didChange(current);
            widget.onChanged?.call(current);
            setSheetState(() {});
          },
        );
      },
    );
  }

  Widget _buildDoctorRow(Staff doc) {
    final selected = widget.state.value ?? [];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        children: [
          AppAvatar(name: doc.fullName, radius: 18),
          const SizedBox(width: AppSizes.p8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(doc.fullName, style: AppTextStyles.bodyBold,
                      overflow: TextOverflow.ellipsis),
                ),
                if (!doc.isActive) ...[
                  const SizedBox(width: AppSizes.p6),
                  Text(AppStrings.deactivated,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (selected.length <= 1) {
                AppSnackbar.show(
                  context,
                  message: 'A patient must have at least one assigned doctor.',
                  variant: AppSnackbarVariant.error,
                );
                return;
              }
              final updated = selected.where((d) => d.id != doc.id).toList();
              widget.state.didChange(updated);
              widget.onChanged?.call(updated);
            },
            child: const Icon(Icons.close, size: AppSizes.iconSmall,
                color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
