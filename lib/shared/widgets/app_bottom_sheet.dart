import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Standard bottom sheet shell with shared chrome, draggable resizing, and wide-screen restraint.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    required this.builder,
    this.initialChildSize = 0.75,
    this.minChildSize = 0.4,
    this.maxChildSize = AppSizes.sheetMax,
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
    double minChildSize = 0.4,
    double maxChildSize = AppSizes.sheetMax,
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

class _BottomSheetFrame extends StatefulWidget {
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
  State<_BottomSheetFrame> createState() => _BottomSheetFrameState();
}

class _BottomSheetFrameState extends State<_BottomSheetFrame> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final double screenHeight = MediaQuery.sizeOf(context).height;
    if (screenHeight > 0 && _sheetController.isAttached) {
      final double deltaFraction = -details.primaryDelta! / screenHeight;
      final double targetSize = (_sheetController.size + deltaFraction).clamp(
        widget.minChildSize,
        widget.maxChildSize,
      );
      _sheetController.jumpTo(targetSize);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_sheetController.isAttached) return;
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity > 800 || _sheetController.size <= widget.minChildSize + 0.05) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bool keyboardVisible = bottomInset > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        controller: _sheetController,
        initialChildSize: keyboardVisible
            ? widget.maxChildSize
            : widget.initialChildSize,
        minChildSize: widget.minChildSize,
        maxChildSize: widget.maxChildSize,
        expand: false,
        builder: (context, scrollController) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: _onDragUpdate,
                        onVerticalDragEnd: _onDragEnd,
                        child: Column(
                          children: [
                            const SizedBox(height: AppSizes.p8),
                            _Handle(color: cs.outlineVariant),
                            const SizedBox(height: AppSizes.p8),
                            _Header(title: widget.title),
                            const SizedBox(height: AppSizes.p8),
                          ],
                        ),
                      ),
                      Expanded(
                        child: widget.builder(context, scrollController),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
