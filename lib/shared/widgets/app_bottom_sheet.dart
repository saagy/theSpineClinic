import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A bottom sheet container styled with Spine Clinic design tokens and DraggableScrollableSheet.
class AppBottomSheet extends StatelessWidget {
  /// Creates an [AppBottomSheet].
  const AppBottomSheet({required this.title, required this.builder, super.key});

  /// Heading label for the modal context.
  final String title;

  /// Builder for the child content using DraggableScrollableSheet's ScrollController.
  final Widget Function(BuildContext, ScrollController) builder;

  /// Scoped static utility to easily display this bottom sheet anywhere.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext, ScrollController) builder,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => AppBottomSheet(title: title, builder: builder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.r16),
            ),
          ),
          child: SafeArea(
            top: false,
            bottom: true, // Guard against hardware phone notch overlaps
            child: Padding(
              // Pushes the bottom sheet up when the phone's soft keyboard is visible
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.p8),
                  // Centered cosmetic drag handle bar
                  Center(
                    child: Container(
                      width: AppSizes.handleWidth,
                      height: AppSizes.handleHeight,
                      decoration: BoxDecoration(
                        color: cs.outline,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppSizes.p2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.p8),
                  // Header title and close button row layout
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.p20,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.headingSmall.copyWith(
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.p12),
                        // Trailing close cross button
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: cs.onSurfaceVariant,
                            size: AppSizes.iconDefault,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.p12),
                  // Sheet body content block
                  Expanded(child: builder(context, scrollController)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
