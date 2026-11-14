import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/record_action_menu.dart';
import '../../../../shared/widgets/record_menu_select.dart';
import '../../domain/billing_report.dart';
import '../billing_report_providers.dart';
import 'report_labels.dart';

/// The reports as text tabs, matching the patient workspace tabs. Narrow
/// windows and enlarged text get one Report menu instead, so no report hides
/// off the edge of the screen.
class ReportTabs extends ConsumerStatefulWidget {
  const ReportTabs({super.key});

  @override
  ConsumerState<ReportTabs> createState() => _ReportTabsState();
}

class _ReportTabsState extends ConsumerState<ReportTabs> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: BillingReportKind.values.length,
    initialIndex: ref.read(billingReportFilterControllerProvider).kind.index,
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int selected = ref.watch(
      billingReportFilterControllerProvider.select((filter) => filter.kind.index),
    );
    final bool still = MediaQuery.disableAnimationsOf(context);
    if (_controller.index != selected) {
      _controller.animateTo(
        selected,
        duration: still ? Duration.zero : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    void select(BillingReportKind kind) =>
        ref.read(billingReportFilterControllerProvider.notifier).setKind(kind);
    return LayoutBuilder(
      builder: (context, box) {
        final bool narrow =
            box.maxWidth < AppSizes.reportTabsMinWidth ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        if (narrow) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p8, AppSizes.p16, 0),
            child: RecordMenuSelect<BillingReportKind>(
              label: AppStrings.billingReports.reportMenu,
              value: BillingReportKind.values[selected],
              isField: true,
              options: [
                for (final kind in BillingReportKind.values)
                  RecordMenuAction(kind, kind.label, kind.icon),
              ],
              onChanged: select,
            ),
          );
        }
        return TabBar(
          controller: _controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: AppTextStyles.bodyBold,
          unselectedLabelStyle: AppTextStyles.body,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p4),
          labelPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
          indicatorSize: TabBarIndicatorSize.tab,
          onTap: (index) {
            if (still) _controller.index = index;
            select(BillingReportKind.values[index]);
          },
          tabs: [for (final kind in BillingReportKind.values) Tab(text: kind.label)],
        );
      },
    );
  }
}
