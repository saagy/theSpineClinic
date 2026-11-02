import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Shared modal surface, keyboard clearance and bounded scrolling for filters.
class FilterSheetFrame extends StatelessWidget {
  const FilterSheetFrame({super.key, required this.child});
  final Widget child;

  static Future<T?> show<T>({required BuildContext context, required WidgetBuilder builder}) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        constraints: const BoxConstraints(maxWidth: AppSizes.filterSheetMaxWidth),
        backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(0),
        builder: builder,
      );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      constraints: BoxConstraints(
        maxHeight:
            (MediaQuery.sizeOf(context).height - MediaQuery.viewInsetsOf(context).bottom) *
            AppSizes.filterSheetHeightFraction,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.r16)),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(top: false, child: child),
      ),
    ),
  );
}

/// Domain filters supply content and callbacks; drafts remain with the caller.
class FilterSheetBody extends StatelessWidget {
  const FilterSheetBody({
    super.key,
    required this.children,
    required this.onReset,
    required this.onApply,
  });
  final List<Widget> children;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p12, AppSizes.p8, AppSizes.p8),
        child: Row(
          children: [
            Expanded(child: Text(AppStrings.filtersButton, style: AppTextStyles.headingMedium)),
            TextButton(
              onPressed: onReset,
              child: Text(AppStrings.resetFilters, style: AppTextStyles.bodyBold),
            ),
            IconButton(
              tooltip: AppStrings.close,
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: AppSizes.iconDefault),
            ),
          ],
        ),
      ),
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(AppSizes.p16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSizes.tappableMin),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
          ),
          onPressed: onApply,
          child: Text(AppStrings.applyFilters, style: AppTextStyles.bodyBold),
        ),
      ),
    ],
  );
}

class FilterSectionTitle extends StatelessWidget {
  const FilterSectionTitle(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.p8),
    child: Text(
      title.toUpperCase(),
      style: AppTextStyles.captionBold.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
