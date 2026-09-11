import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';

/// Native animated indicator and horizontal reveal without scrolling the page.
class WorkspaceTabs extends ConsumerStatefulWidget {
  const WorkspaceTabs({super.key, required this.patientId, required this.labels});
  final String patientId;
  final List<String> labels;

  @override
  ConsumerState<WorkspaceTabs> createState() => _WorkspaceTabsState();
}

class _WorkspaceTabsState extends ConsumerState<WorkspaceTabs>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    _controller = TabController(
      length: widget.labels.length,
      initialIndex: ref.read(patientActiveTabProvider(widget.patientId)).clamp(0, widget.labels.length - 1),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant WorkspaceTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length || oldWidget.patientId != widget.patientId) {
      _controller.dispose();
      _createController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(patientActiveTabProvider(widget.patientId)).clamp(0, widget.labels.length - 1);
    if (_controller.index != selected) {
      _controller.animateTo(
        selected,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    return TabBar(
      controller: _controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelStyle: AppTextStyles.bodyBold,
      unselectedLabelStyle: AppTextStyles.body,
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
      indicatorSize: TabBarIndicatorSize.tab,
      onTap: (index) {
        if (MediaQuery.disableAnimationsOf(context)) _controller.index = index;
        ref.read(patientActiveTabProvider(widget.patientId).notifier).setTab(index);
      },
      tabs: [for (final label in widget.labels) Tab(text: label)],
    );
  }
}
