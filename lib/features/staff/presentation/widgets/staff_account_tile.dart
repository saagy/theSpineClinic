import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_account_status.dart';
import 'package:spine_clinic_app/shared/widgets/app_avatar.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';

class StaffAccountTile extends StatelessWidget {
  const StaffAccountTile({
    super.key,
    required this.staff,
    this.onTap,
    this.action,
    this.showCreatedDate = false,
    this.transparent = false,
  });

  final Staff staff;
  final VoidCallback? onTap;
  final Widget? action;
  final bool showCreatedDate;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    return DataListTile(
      title: staff.fullName,
      subtitle: _subtitle,
      subtitleMaxLines: 2,
      leading: AppAvatar(name: staff.fullName, color: _avatarColor(context)),
      trailing: action ?? _Badges(staff: staff),
      transparent: transparent,
      onTap: onTap,
    );
  }

  String get _subtitle {
    final parts = <String>[
      staff.email,
      staff.phone == null || staff.phone!.trim().isEmpty
          ? AppStrings.noPhone
          : Formatters.formatPhone(staff.phone!),
      if (staff.role == UserRole.receptionist)
        staff.branch?.displayLabel ?? AppStrings.noBranch,
      if (showCreatedDate) staff.createdAt.toShortDateString(),
    ];
    return parts.join(' | ');
  }

  Color _avatarColor(BuildContext context) {
    final clinic = ClinicColors.of(context);
    return switch (staff.accountStatus) {
      StaffAccountStatus.active => clinic.success,
      StaffAccountStatus.pending => Theme.of(context).colorScheme.primary,
      StaffAccountStatus.deactivated => clinic.neutral,
    };
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.staff});

  final Staff staff;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _roleBadge(context),
        const SizedBox(height: AppSizes.p4),
        _statusBadge(context),
      ],
    );
  }

  AppBadge _roleBadge(BuildContext context) {
    final clinic = ClinicColors.of(context);
    final label = switch (staff.role) {
      UserRole.superAdmin => AppStrings.superAdmin,
      UserRole.receptionist => AppStrings.receptionist,
      UserRole.doctor => AppStrings.doctor,
    };
    final color = switch (staff.role) {
      UserRole.superAdmin => clinic.neutral,
      UserRole.receptionist => clinic.info,
      UserRole.doctor => Theme.of(context).colorScheme.primary,
    };
    final bg = switch (staff.role) {
      UserRole.superAdmin => clinic.neutralContainer,
      UserRole.receptionist => clinic.infoContainer,
      UserRole.doctor => Theme.of(context).colorScheme.primaryContainer,
    };
    return AppBadge(label: label, textColor: color, backgroundColor: bg);
  }

  AppBadge _statusBadge(BuildContext context) {
    final status = staff.accountStatus;
    final clinic = ClinicColors.of(context);
    final color = switch (status) {
      StaffAccountStatus.active => clinic.success,
      StaffAccountStatus.pending => Theme.of(context).colorScheme.primary,
      StaffAccountStatus.deactivated => Theme.of(context).colorScheme.error,
    };
    final bg = switch (status) {
      StaffAccountStatus.active => clinic.successContainer,
      StaffAccountStatus.pending => Theme.of(
        context,
      ).colorScheme.primaryContainer,
      StaffAccountStatus.deactivated => Theme.of(
        context,
      ).colorScheme.errorContainer,
    };
    return AppBadge(label: status.label, textColor: color, backgroundColor: bg);
  }
}
