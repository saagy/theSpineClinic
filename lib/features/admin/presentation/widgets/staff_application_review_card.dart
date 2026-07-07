import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/admin/presentation/widgets/application_action_buttons.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_tile.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

class StaffApplicationReviewCard extends StatelessWidget {
  const StaffApplicationReviewCard({
    super.key,
    required this.staff,
    required this.onApprove,
    required this.onReject,
    required this.isLoading,
  });

  final Staff staff;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaffAccountTile(
            staff: staff,
            showCreatedDate: true,
            transparent: true,
          ),
          const SizedBox(height: AppSizes.p12),
          ApplicationActionButtons(
            onApprove: onApprove,
            onReject: onReject,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}
