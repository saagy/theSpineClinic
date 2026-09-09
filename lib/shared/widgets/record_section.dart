import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';

/// Flat record sections with aligned heading rules and accessible actions.
class RecordSection extends StatelessWidget {
  const RecordSection({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.onAction,
    this.primaryAction = false,
    this.trailing,
    this.showTitle = true,
  });
  final String title;
  final Widget child;
  final String? action;
  final VoidCallback? onAction;
  final bool primaryAction;
  final Widget? trailing;
  final bool showTitle;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: AppSizes.p20),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle || action != null || trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSizes.p12,
              runSpacing: AppSizes.p8,
              children: [
                if (showTitle)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
                    child: Align(
                      widthFactor: 1,
                      alignment: Alignment.centerLeft,
                      child: Text(title, style: AppTextStyles.headingSmall),
                    ),
                  ),
                if (trailing != null) trailing!,
                if (action != null)
                  if (primaryAction)
                    RecordAddButton(label: action!, onPressed: onAction)
                  else
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
                      ),
                      child: Text(action!, style: AppTextStyles.captionBold),
                    ),
              ],
            ),
          ),
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
            child: child,
          ),
        ),
      ],
    ),
  );
}

/// Section-local resilience: a failed document request never hides clinical data.
class RecordAsync<T> extends StatelessWidget {
  const RecordAsync({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.skeleton = const RecordSkeleton(),
  });
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback onRetry;
  final Widget skeleton;

  @override
  Widget build(BuildContext context) => RecordTransition(
    child: value.when(
      data: data,
      loading: () => skeleton,
      error: (_, _) =>
          RecordMessage(message: AppStrings.patientSectionError, action: AppStrings.retry, onAction: onRetry),
    ),
  );
}

class RecordAddButton extends StatelessWidget {
  const RecordAddButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
    ),
    icon: const Icon(Icons.add, size: AppSizes.iconSmall),
    label: Text(label, style: AppTextStyles.bodyBold),
  );
}

class RecordMessage extends StatelessWidget {
  const RecordMessage({super.key, required this.message, this.action, this.onAction});
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
    child: Wrap(
      spacing: AppSizes.p12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          message,
          style: AppTextStyles.body.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class RecordFact extends StatelessWidget {
  const RecordFact({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSizes.p4),
        SelectableText(value, style: AppTextStyles.bodyMedium),
      ],
    ),
  );
}
