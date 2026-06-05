import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/add_visit_notes_controller.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/app_text_field.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/info_row.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// Screen allowing authorized doctors or super admins to add/edit visit notes.
class AddVisitNotesScreen extends ConsumerWidget {
  /// Creates an [AddVisitNotesScreen].
  const AddVisitNotesScreen({super.key, required this.appointmentId});

  /// The target appointment's unique ID.
  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AddVisitNotesState> stateAsync =
        ref.watch(addVisitNotesControllerProvider(appointmentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Add Visit Notes',
          style: AppTextStyles.headingSmall,
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(),
      ),
      body: stateAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (Object error, StackTrace stack) => ErrorView(
          exception: error is AppException
              ? error
              : AppException.fromSupabaseException(error),
          onRetry: () =>
              ref.invalidate(addVisitNotesControllerProvider(appointmentId)),
        ),
        data: (AddVisitNotesState state) {
          if (!state.isAuthorized) {
            return const _SecurityRestrictionView();
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header details
                Padding(
                  padding: const EdgeInsets.all(AppSizes.p24),
                  child: SectionCard(
                    child: Column(
                      children: [
                        InfoRow(
                          label: 'Patient',
                          value: state.patient.fullName,
                        ),
                        InfoRow(
                          label: AppStrings.date,
                          value: Formatters.formatDateMedium(
                            state.appointment.scheduledAt,
                          ),
                        ),
                        InfoRow(
                          label: AppStrings.time,
                          value: Formatters.formatTime(
                            state.appointment.scheduledAt,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form details
                _NotesForm(
                  appointment: state.appointment,
                  appointmentId: appointmentId,
                  widgetRef: ref,
                ),
                const SizedBox(height: AppSizes.p32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SecurityRestrictionView extends StatelessWidget {
  const _SecurityRestrictionView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.p16),
            Text(
              'Access Denied',
              style: AppTextStyles.headingLarge
                  .copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p8),
            Text(
              'Only the assigned doctor or a super admin can access or modify visit notes.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.p24),
            AppButton(
              labelText: 'Go Back',
              onPressed: () => Navigator.of(context).pop(),
              variant: AppButtonVariant.secondary,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesForm extends StatefulWidget {
  const _NotesForm({
    required this.appointment,
    required this.appointmentId,
    required this.widgetRef,
  });

  final Appointment appointment;
  final String appointmentId;
  final WidgetRef widgetRef;

  @override
  State<_NotesForm> createState() => _NotesFormState();
}

class _NotesFormState extends State<_NotesForm> {
  late final TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.appointment.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await widget.widgetRef
          .read(addVisitNotesControllerProvider(widget.appointmentId).notifier)
          .saveNotes(_notesController.text.trim());
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Notes saved successfully.',
          variant: AppSnackbarVariant.success,
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        final String errorMsg =
            e is AppException ? e.message : e.toString();
        AppSnackbar.show(
          context,
          message: 'Failed to save notes: $errorMsg',
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleComplete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.markAsCompleted,
        message: AppStrings.confirmMarkComplete,
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      await widget.widgetRef
          .read(addVisitNotesControllerProvider(widget.appointmentId).notifier)
          .completeAppointment(_notesController.text.trim());
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'Appointment completed.',
          variant: AppSnackbarVariant.success,
        );
        Navigator.of(context).pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        final String errorMsg =
            e is AppException ? e.message : e.toString();
        AppSnackbar.show(
          context,
          message: 'Failed to complete appointment: $errorMsg',
          variant: AppSnackbarVariant.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canComplete =
        widget.appointment.status == AppointmentStatus.checkedIn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _notesController,
            labelText: AppStrings.notes,
            hintText: 'Enter visit progress notes...',
            maxLines: 8,
            enabled: !_isSaving,
          ),
          const SizedBox(height: AppSizes.p24),
          AppButton(
            labelText: 'Save Notes',
            onPressed: _isSaving ? null : _handleSave,
            isLoading: _isSaving && !canComplete,
            variant: AppButtonVariant.primary,
          ),
          if (canComplete) ...[
            const SizedBox(height: AppSizes.p12),
            AppButton(
              labelText: AppStrings.markComplete,
              onPressed: _isSaving ? null : _handleComplete,
              isLoading: _isSaving && canComplete,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
