/// Custom search bar widget matching the Spine Clinic input design tokens.
///
/// Provides inline debounced search functionality (300ms) and clear button,
/// styled with flat white background and Slate borders. Touch-only design.
///
/// Rule 1 — keep files under 200 lines.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';

/// A standard debounced search input styled with Spine Clinic design tokens.
class AppSearchBar extends StatefulWidget {
  /// Creates an [AppSearchBar].
  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.enabled = true,
  });

  /// Placeholder text displayed inside the field.
  final String hintText;

  /// Callback fired 300ms after user stops typing.
  final ValueChanged<String> onChanged;

  /// Optional callback fired when the clear button is tapped.
  final VoidCallback? onClear;

  /// Whether the search bar is interactive.
  final bool enabled;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    // Rebuild to evaluate if clear icon should show/hide
    setState(() {});

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onChanged(text);
      }
    });
  }

  void _handleClear() {
    _debounceTimer?.cancel();
    _controller.clear();
    setState(() {});

    // Clear instantly
    widget.onChanged('');
    if (widget.onClear != null) {
      widget.onClear!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ClinicColors clinic = ClinicColors.of(context);
    // Match AppTextField border styling exactly
    final OutlineInputBorder borderBase = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
      borderSide: BorderSide(color: cs.outline, width: AppSizes.borderWidth),
    );

    return SizedBox(
      height: AppSizes.h48, // Standardized action height (48 px)
      child: TextFormField(
        controller: _controller,
        onChanged: _onTextChanged,
        enabled: widget.enabled,
        style: AppTextStyles.body.copyWith(
          color: widget.enabled ? cs.onSurface : clinic.textMuted,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: widget.enabled ? cs.surface : cs.surfaceContainer,
          hintText: widget.hintText,
          hintStyle: AppTextStyles.bodySecondary.copyWith(
            color: clinic.textMuted,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSizes.p12,
            horizontal: AppSizes.p12,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: cs.onSurfaceVariant,
            size: AppSizes.iconDefault,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: AppSizes.iconDefault + AppSizes.p16,
            minHeight: AppSizes.iconDefault,
          ),
          suffixIcon: _controller.text.isNotEmpty && widget.enabled
              ? GestureDetector(
                  onTap: _handleClear,
                  child: Icon(
                    Icons.close,
                    color: cs.onSurfaceVariant,
                    size: AppSizes.iconDefault,
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: AppSizes.iconDefault + AppSizes.p16,
            minHeight: AppSizes.iconDefault,
          ),
          // Default border state
          enabledBorder: borderBase,
          // Disabled border state
          disabledBorder: borderBase.copyWith(
            borderSide: BorderSide(
              color: cs.outline,
              width: AppSizes.borderWidth,
            ),
          ),
          // Focus border state (transitions cleanly using Flutter's native focus engine)
          focusedBorder: borderBase.copyWith(
            borderSide: BorderSide(
              color: clinic.outlineStrong,
              width: AppSizes.borderWidthFocused,
            ),
          ),
        ),
      ),
    );
  }
}
