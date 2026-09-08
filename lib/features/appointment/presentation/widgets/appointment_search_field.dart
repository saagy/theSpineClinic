/// Single-surface search field for the appointment directory header.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Single-surface debounced search field used by the all-appointments header.
class AppointmentSearchField extends StatefulWidget {
  const AppointmentSearchField({
    super.key,
    required this.onChanged,
    this.initialValue,
    this.hintText,
  });

  final ValueChanged<String> onChanged;
  final String? initialValue;
  final String? hintText;

  @override
  State<AppointmentSearchField> createState() => _AppointmentSearchFieldState();
}

class _AppointmentSearchFieldState extends State<AppointmentSearchField> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(AppointmentSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null &&
        widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String val) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onChanged(val.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.r8),
      borderSide: BorderSide(
        color: cs.outlineVariant,
        width: AppSizes.borderWidth,
      ),
    );

    return SizedBox(
      height: AppSizes.tappableMin,
      child: TextField(
        controller: _controller,
        onChanged: _onTextChanged,
        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
        decoration: InputDecoration(
          filled: true,
          fillColor: cs.surface,
          hintText: widget.hintText ?? AppStrings.searchByPatientNameHint,
          hintStyle: AppTextStyles.caption.copyWith(
            color: cs.onSurfaceVariant.withAlpha(140),
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            size: AppSizes.iconSmall,
            color: cs.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: AppSizes.iconSmall,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _debounceTimer?.cancel();
                    _controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p12,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(
              color: cs.primary,
              width: AppSizes.borderWidthFocused,
            ),
          ),
        ),
      ),
    );
  }
}
