import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';

/// Clean tab strip dividing Schedule, Booking, and All views on the appointments screen.
class ReceptionistAppointmentsTabStrip extends StatelessWidget {
  const ReceptionistAppointmentsTabStrip({required this.controller, super.key});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withAlpha(100),
              width: AppSizes.borderWidth,
            ),
          ),
        ),
        child: TabBar(
          controller: controller,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          labelStyle: AppTextStyles.bodyBold.copyWith(fontSize: 13.5),
          unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(
            fontSize: 13.5,
          ),
          indicatorColor: cs.primary,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: AppStrings.schedule),
            Tab(text: AppStrings.booking),
            Tab(text: AppStrings.all),
          ],
        ),
      ),
    );
  }
}
