import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/visit_detail_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';

/// Pushed full-screen route for viewing completed clinical visit notes.
class VisitDetailScreen extends ConsumerWidget {
  /// Creates a [VisitDetailScreen].
  const VisitDetailScreen({super.key, required this.appointmentId});

  /// The appointment ID of the visit to detail.
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(visitDetailControllerProvider(appointmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.visitDetails, style: AppTextStyles.headingSmall),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        leading: const AppBackButton(),
        actions: [
          stateAsync.maybeWhen(
            data: (state) => state.canEditNotes
                ? IconButton(
                    icon: const Icon(Icons.edit_note_rounded),
                    tooltip: AppStrings.editNotesTooltip,
                    onPressed: () => context.push(
                      AppRoutes.addVisitNotes.replaceAll(':id', appointmentId),
                    ),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => ErrorView(
          exception: err is AppException ? err : AppException.fromSupabaseException(err),
          onRetry: () => ref.invalidate(visitDetailControllerProvider(appointmentId)),
        ),
        data: (state) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoSection(context, state),
              const SizedBox(height: AppSizes.p16),
              _buildDoctorsSection(state),
              const SizedBox(height: AppSizes.p16),
              _buildNotesSection(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, VisitDetailState state) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(AppRoutes.patientDetail.replaceAll(':id', state.patient.id)),
            borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r4)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, color: AppColors.primary, size: AppSizes.iconDefault),
                  const SizedBox(width: AppSizes.p8),
                  Expanded(
                    child: Text(
                      state.patient.fullName,
                      style: AppTextStyles.bodyBold.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: AppSizes.p24),
          InfoRow(label: AppStrings.date, value: Formatters.formatDateMedium(state.appointment.scheduledAt)),
          InfoRow(label: AppStrings.time, value: Formatters.formatTime(state.appointment.scheduledAt)),
          const SizedBox(height: AppSizes.p12),
          Row(
            children: [
              AppBadge(
                label: state.appointment.type.displayLabel,
                textColor: state.appointment.type.textColor,
                backgroundColor: state.appointment.type.backgroundColor,
              ),
              const SizedBox(width: AppSizes.p8),
              AppBadge(
                label: state.appointment.status.displayLabel,
                textColor: state.appointment.status.textColor,
                backgroundColor: state.appointment.status.backgroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsSection(VisitDetailState state) {
    return SectionCard(
      title: AppStrings.attendingStaff,
      child: state.activeDoctors.isEmpty
          ? Text(AppStrings.noStaffAssignedToSession, style: AppTextStyles.caption)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: state.activeDoctors.map((docDetail) {
                final bool isReplacement = docDetail.assignment.isReplacement;
                final String? replacedDoctorName = docDetail.replacedDoctor?.fullName;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, color: AppColors.textSecondary, size: AppSizes.iconSmall),
                      const SizedBox(width: AppSizes.p8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.body,
                            children: [
                              TextSpan(text: docDetail.doctor.fullName, style: AppTextStyles.bodyMedium),
                              if (isReplacement && replacedDoctorName != null)
                                TextSpan(
                                  text: ' (Covering $replacedDoctorName)',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNotesSection(VisitDetailState state) {
    final noteText = state.note?.noteText;
    return SectionCard(
      title: 'Clinical Visit Notes',
      child: Text(
        noteText?.isNotEmpty == true ? noteText! : 'No visit notes recorded for this session.',
        style: AppTextStyles.body.copyWith(
          color: noteText?.isNotEmpty == true ? AppColors.textPrimary : AppColors.textMuted,
          fontStyle: noteText?.isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }
}
