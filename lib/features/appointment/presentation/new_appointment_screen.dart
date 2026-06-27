import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/new_appointment_form.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';

/// Screen container for booking a new single or recurring appointment.
class NewAppointmentScreen extends ConsumerWidget {
  /// Creates a [NewAppointmentScreen].
  const NewAppointmentScreen({super.key, this.preselectedPatientId});

  /// Optional patient ID to pre-populate.
  final String? preselectedPatientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    final user = asyncUser.value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!asyncUser.isLoading && (user == null || user.role == UserRole.doctor)) {
        AppSnackbar.show(context,
            message: AppStrings.accessDenied, variant: AppSnackbarVariant.error);
        context.pop();
      }
    });

    if (asyncUser.isLoading || user == null || user.role == UserRole.doctor) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.newAppointment),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: const AppBackButton(),
      ),
      body: NewAppointmentForm(preselectedPatientId: preselectedPatientId),
    );
  }
}
