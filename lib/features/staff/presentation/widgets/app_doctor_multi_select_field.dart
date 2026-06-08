import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/doctor_overlay_list.dart';
import 'package:spine_clinic_app/shared/widgets/app_chip.dart';

/// Reusable searchable custom form field for doctor multi-selection.
///
/// Features debounced search, custom overlay dropdown, and high-density chips.
class AppDoctorMultiSelectField extends FormField<List<Staff>> {
  /// Creates an [AppDoctorMultiSelectField].
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
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchCtrl = TextEditingController();
  OverlayEntry? _overlayEntry;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    _hideOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim());
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: _layerLink.leaderSize?.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0.0, 52.0),
            child: TapRegion(
              groupId: this,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(AppSizes.r6),
                color: AppColors.surface,
                child: DoctorOverlayList(
                  searchQuery: _searchQuery,
                  selectedDoctors: widget.state.value ?? [],
                  onTap: (doctor) {
                    final current = List<Staff>.from(widget.state.value ?? []);
                    final isSel = current.any((d) => d.id == doctor.id);
                    if (isSel) {
                      current.removeWhere((d) => d.id == doctor.id);
                    } else {
                      current.add(doctor);
                    }
                    widget.state.didChange(current);
                    widget.onChanged?.call(current);
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                    _focusNode.unfocus();
                    _hideOverlay();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.state.value ?? [];
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: BorderSide(
        color: widget.state.hasError ? AppColors.error : AppColors.border,
        width: AppSizes.borderWidth,
      ),
    );

    return TapRegion(
      groupId: this,
      onTapOutside: (event) {
        _hideOverlay();
        _focusNode.unfocus();
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchCtrl,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
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
              Wrap(
                spacing: AppSizes.p8,
                runSpacing: AppSizes.p8,
                children: selected.map((doctor) {
                  return AppChip(
                    label: doctor.fullName,
                    onDeleted: () {
                      final updated = selected.where((d) => d.id != doctor.id).toList();
                      widget.state.didChange(updated);
                      widget.onChanged?.call(updated);
                    },
                  );
                }).toList(),
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
        ),
      ),
    );
  }
}
