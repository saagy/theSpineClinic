import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Standard bottom sheet shell with shared chrome and wide-screen restraint.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    required this.builder,
    this.initialChildSize = 0.75,
    this.minChildSize = 0.5,
    this.maxChildSize = 0.95,
    this.maxWidth = AppSizes.profileLayoutMaxWidth,
  });

  final String title;
  final Widget Function(BuildContext, ScrollController) builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final double maxWidth;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext, ScrollController) builder,
    bool isScrollControlled = true,
    double initialChildSize = 0.75,
    double minChildSize = 0.5,
    double maxChildSize = 0.95,
    double maxWidth = AppSizes.profileLayoutMaxWidth,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(0),
      elevation: 0,
      builder: (context) => AppBottomSheet(
        title: title,
        builder: builder,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        maxWidth: maxWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: _BottomSheetFrame(
            title: title,
            builder: builder,
            initialChildSize: initialChildSize,
            minChildSize: minChildSize,
            maxChildSize: maxChildSize,
            maxWidth: maxWidth,
          ),
        ),
      ),
    );
  }
}

class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({
    required this.title,
    required this.builder,
    required this.initialChildSize,
    required this.minChildSize,
    required this.maxChildSize,
    required this.maxWidth,
  });

  final String title;
  final Widget Function(BuildContext, ScrollController) builder;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (context, scrollController) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.r16),
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSizes.p8),
                      _Handle(color: cs.outlineVariant),
                      const SizedBox(height: AppSizes.p8),
                      _Header(title: title),
                      const SizedBox(height: AppSizes.p12),
                      Expanded(child: builder(context, scrollController)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSizes.handleWidth,
        height: AppSizes.handleHeight,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.p2)),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(color: cs.onSurface),
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          IconButton(
            icon: Icon(
              Icons.close,
              color: cs.onSurfaceVariant,
              size: AppSizes.iconDefault,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
