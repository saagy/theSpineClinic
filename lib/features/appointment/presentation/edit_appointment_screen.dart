import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/edit_appointment_form.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Screen for editing an existing appointment's details.
class EditAppointmentScreen extends ConsumerWidget {
  const EditAppointmentScreen({super.key, required this.appointmentId});
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(currentUserProvider);
    final user = asyncUser.value;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!asyncUser.isLoading && user == null) {
        AppSnackbar.show(context,
            message: AppStrings.accessDenied,
            variant: AppSnackbarVariant.error);
        context.pop();
      }
    });

    if (asyncUser.isLoading || user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final detailAsync =
        ref.watch(appointmentDetailControllerProvider(appointmentId));

    final Widget body;
    if (detailAsync.isLoading && !detailAsync.hasValue) {
      body = const Padding(
        padding: EdgeInsets.all(AppSizes.p16),
        child: SkeletonTileList(count: 5),
      );
    } else if (detailAsync.hasError && !detailAsync.hasValue) {
      final error = detailAsync.error!;
      body = ErrorView(
        exception: error is AppException
            ? error
            : AppException.fromSupabaseException(error),
        onRetry: () => ref.invalidate(
            appointmentDetailControllerProvider(appointmentId)),
      );
    } else {
      final state = detailAsync.value!;
      body = EditAppointmentForm(
        appointment: state.appointment,
        patient: state.patient,
        initialDoctors:
            state.activeDoctors.map((d) => d.doctor).toList(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.editAppointment),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: const AppBackButton(),
      ),
      body: body,
    );
  }
}
