import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/new_appointment_form.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';

/// Screen container for booking a new single or recurring appointment.
class NewAppointmentScreen extends ConsumerWidget {
  /// Creates a [NewAppointmentScreen].
  const NewAppointmentScreen({
    super.key,
    this.preselectedPatientId,
    this.preselectedDate,
    this.preselectedDoctorId,
    this.expectedNextVisitDate,
  });

  /// Optional patient ID to pre-populate.
  final String? preselectedPatientId;
  final DateTime? preselectedDate;
  final String? preselectedDoctorId;
  final DateTime? expectedNextVisitDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    final user = asyncUser.value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!asyncUser.isLoading &&
          (user == null ||
              (user.role == UserRole.doctor && !user.isSeniorDoctor))) {
        AppSnackbar.show(
          context,
          message: AppStrings.accessDenied,
          variant: AppSnackbarVariant.error,
        );
        context.pop();
      }
    });

    if (asyncUser.isLoading ||
        user == null ||
        (user.role == UserRole.doctor && !user.isSeniorDoctor)) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.newAppointment),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: const AppBackButton(),
      ),
      body: NewAppointmentForm(
        preselectedPatientId: preselectedPatientId,
        preselectedDate: preselectedDate,
        preselectedDoctorId: preselectedDoctorId,
        expectedNextVisitDate: expectedNextVisitDate,
      ),
    );
  }
}
