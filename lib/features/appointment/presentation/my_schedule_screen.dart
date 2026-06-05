import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/my_schedule_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/schedule_list_view.dart';

/// Screen displaying the active doctor's daily agenda or weekly grouped timeline.
class MyScheduleScreen extends ConsumerWidget {
  /// Creates a [MyScheduleScreen].
  const MyScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(myScheduleControllerProvider);
    final controller = ref.read(myScheduleControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSegmentedControl(
              context,
              ref,
              scheduleAsync.value?.horizon ?? MyScheduleHorizon.today,
            ),
            Expanded(
              child: ScheduleListView(
                state: scheduleAsync,
                onRetry: () => controller.refresh(),
                onRefresh: () => controller.refresh(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(
    BuildContext context,
    WidgetRef ref,
    MyScheduleHorizon activeHorizon,
  ) {
    final controller = ref.read(myScheduleControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p16, AppSizes.p16, AppSizes.p8),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p4),
        decoration: BoxDecoration(
          color: AppColors.border.withAlpha(100),
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _SegmentButton(
                label: 'Today',
                isActive: activeHorizon == MyScheduleHorizon.today,
                onTap: () => controller.toggleHorizon(MyScheduleHorizon.today),
              ),
            ),
            Expanded(
              child: _SegmentButton(
                label: 'This Week',
                isActive: activeHorizon == MyScheduleHorizon.week,
                onTap: () => controller.toggleHorizon(MyScheduleHorizon.week),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surface : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r6)),
          boxShadow: isActive ? const [AppColors.cardShadow] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyBold.copyWith(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
