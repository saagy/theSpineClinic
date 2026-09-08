/// Management screen listing all appointments across doctors and branches.
///
/// Accessible to admin and receptionist roles only. Supports combinable
/// filters: date range, doctor, branch, status, and patient name search.
/// Desktop page navigation on wide screens; infinite scroll on mobile.
///
/// Rule 1 — under 200 lines.
/// Rule 9 — handles loading, error, empty, and data states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_tab.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';

/// Full-screen management view of all appointments with desktop page navigation
/// and mobile infinite scroll.
class AllAppointmentsScreen extends ConsumerWidget {
  /// Creates an [AllAppointmentsScreen].
  const AllAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user == null ||
        (user.role != UserRole.superAdmin &&
            user.role != UserRole.receptionist)) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const ErrorView(
          exception: UnknownException(
            message: AppStrings.accessDeniedAdminReceptionOnly,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        title: Text(
          AppStrings.allAppointments,
          style: AppTextStyles.headingSmall,
        ),
      ),
      body: ReceptionistAllTab(
        onStatusChanged: () =>
            ref.read(allAppointmentsProvider.notifier).refresh(),
      ),
    );
  }
}