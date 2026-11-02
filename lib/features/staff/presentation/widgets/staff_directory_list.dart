import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_tile.dart';

/// Preserve global sort order instead of regrouping by role.
class StaffDirectoryList extends StatelessWidget {
  const StaffDirectoryList({super.key, required this.staffList, required this.onTap});
  final List<Staff> staffList;
  final ValueChanged<Staff> onTap;
  @override
  Widget build(BuildContext context) => ListView.separated(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(AppSizes.p16, 0, AppSizes.p16, AppSizes.p16),
    itemCount: staffList.length,
    separatorBuilder: (context, index) =>
        Divider(height: AppSizes.borderWidth, color: Theme.of(context).colorScheme.outlineVariant),
    itemBuilder: (context, index) => StaffAccountTile(
      key: ValueKey(staffList[index].id),
      staff: staffList[index],
      onTap: () => onTap(staffList[index]),
    ),
  );
}
