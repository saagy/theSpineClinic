import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_tile.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';
import 'package:spine_clinic_app/shared/widgets/section_header.dart';

/// Sealed class to represent different kinds of items in the flat list.
sealed class StaffListItem {}

/// A header item representing a role category.
class HeaderItem extends StaffListItem {
  HeaderItem(this.title);
  final String title;
}

/// A card item representing a single staff member.
class CardItem extends StaffListItem {
  CardItem(this.staff);
  final Staff staff;
}

/// A list view widget that groups staff members by their role
/// and displays them under corresponding section headers.
class StaffGroupedList extends StatelessWidget {
  /// Creates a [StaffGroupedList].
  const StaffGroupedList({
    super.key,
    required this.staffList,
    required this.animatedIndices,
    this.onTap,
  });

  /// The list of staff members to display.
  final List<Staff> staffList;

  /// The set of indices that have already animated.
  final Set<int> animatedIndices;

  /// Optional callback when a staff card is tapped.
  final void Function(Staff)? onTap;

  @override
  Widget build(BuildContext context) {
    final items = <StaffListItem>[];

    // Order of sections: Super Admin -> Doctor -> Receptionist
    final roleSections = const [
      UserRole.superAdmin,
      UserRole.doctor,
      UserRole.receptionist,
    ];

    for (final role in roleSections) {
      final roleStaffList = staffList.where((s) => s.role == role).toList();
      if (roleStaffList.isNotEmpty) {
        items.add(HeaderItem(_roleHeaderLabel(role)));
        items.addAll(roleStaffList.map(CardItem.new));
      }
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        switch (item) {
          case HeaderItem():
            return Padding(
              padding: const EdgeInsets.only(top: AppSizes.p16),
              child: SectionHeader(
                title: item.title,
                padding: EdgeInsets.zero,
              ),
            );
          case CardItem():
            return AnimatedListItem(
              index: index,
              animatedIndices: animatedIndices,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.p12),
                child: StaffAccountTile(
                  staff: item.staff,
                  onTap: onTap != null ? () => onTap!(item.staff) : null,
                ),
              ),
            );
        }
      },
    );
  }

  String _roleHeaderLabel(UserRole role) {
    return switch (role) {
      UserRole.superAdmin => AppStrings.superAdmins,
      UserRole.doctor => AppStrings.doctors,
      UserRole.receptionist => AppStrings.receptionists,
    };
  }
}
