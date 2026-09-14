import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// A temporary selection step that keeps the underlying sheet form mounted.
class SheetStepHost extends StatefulWidget {
  const SheetStepHost({
    super.key,
    required this.title,
    required this.child,
    this.onVerticalDragUpdate,
    this.onVerticalDragEnd,
  });

  final String title;
  final Widget child;
  final GestureDragUpdateCallback? onVerticalDragUpdate;
  final GestureDragEndCallback? onVerticalDragEnd;

  static SheetStepHostState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<SheetStepHostState>();

  @override
  State<SheetStepHost> createState() => SheetStepHostState();
}

class SheetStepHostState extends State<SheetStepHost> {
  Widget? _step;
  String? _title;
  LocalHistoryEntry? _history;
  VoidCallback? _cancel;

  Future<T?> showStep<T>({
    required String title,
    required Widget Function(ValueChanged<T>) builder,
  }) {
    final Completer<T?> result = Completer<T?>();
    FocusScope.of(context).unfocus();
    _history?.remove();
    void complete(T? value) {
      if (!result.isCompleted) result.complete(value);
    }

    final LocalHistoryEntry history = LocalHistoryEntry(
      onRemove: () {
        complete(null);
        if (!mounted) return;
        setState(() {
          _step = null;
          _title = null;
          _history = null;
          _cancel = null;
        });
      },
    );
    ModalRoute.of(context)!.addLocalHistoryEntry(history);
    setState(() {
      _history = history;
      _cancel = () => complete(null);
      _title = title;
      _step = builder((value) {
        FocusScope.of(context).unfocus();
        complete(value);
        history.remove();
      });
    });
    return result.future;
  }

  @override
  void dispose() {
    _cancel?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: widget.onVerticalDragUpdate,
        onVerticalDragEnd: widget.onVerticalDragEnd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p20),
          child: Row(
            children: [
              if (_step != null)
                IconButton(
                  tooltip: AppStrings.backTooltip,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _history?.remove();
                  },
                ),
              Expanded(
                child: Text(
                  _title ?? widget.title,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (_step == null) ...[
                const SizedBox(width: AppSizes.p12),
                IconButton(
                  tooltip: AppStrings.close,
                  icon: const Icon(Icons.close, size: AppSizes.iconDefault),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSizes.p8),
      Expanded(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: _step != null,
              child: ExcludeFocus(
                excluding: _step != null,
                child: widget.child,
              ),
            ),
            if (_step != null) _step!,
          ],
        ),
      ),
    ],
  );
}
