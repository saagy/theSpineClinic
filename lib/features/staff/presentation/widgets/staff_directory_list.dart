import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_details_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_tile.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_schedule_label.dart';

/// Preserve global sort order instead of regrouping by role.
class StaffDirectoryList extends ConsumerWidget {
  const StaffDirectoryList({super.key, required this.staffList, required this.onTap});
  final List<Staff> staffList;
  final ValueChanged<Staff> onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(staffSchedulesProvider).value ?? const {};
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, 0, AppSizes.p16, AppSizes.p16),
      itemCount: staffList.length,
      separatorBuilder: (context, index) =>
          Divider(height: AppSizes.borderWidth, color: Theme.of(context).colorScheme.outlineVariant),
      itemBuilder: (context, index) => StaffAccountTile(
        key: ValueKey(staffList[index].id),
        staff: staffList[index],
        schedule: staffScheduleLabel(context, schedules[staffList[index].id]),
        onTap: () => onTap(staffList[index]),
      ),
    );
  }
}
