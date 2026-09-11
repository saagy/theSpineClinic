import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/medical_records/domain/patient_note.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/patient_note_actions_controller.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_monogram_badge.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_note_editor.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/record_action_menu.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

class WorkspaceNoteRow extends ConsumerWidget {
  const WorkspaceNoteRow({super.key, required this.note});
  final PatientNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorAsync = ref.watch(staffProfileProvider(note.createdBy));
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: authorAsync.when(
                  data: (staff) => PatientMonogramBadge(
                    key: ValueKey('badge_${staff.id}'),
                    name: staff.fullName,
                    size: AppSizes.p28,
                  ),
                  loading: () => const SkeletonCircle(
                    key: ValueKey('author_badge_skeleton'),
                    radius: AppSizes.p28 / 2,
                  ),
                  error: (_, _) => const PatientMonogramBadge(
                    name: '',
                    size: AppSizes.p28,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.p10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: authorAsync.when(
                          data: (staff) => Text(
                            staff.fullName,
                            key: ValueKey('author_name_${staff.id}'),
                            style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                          ),
                          loading: () => const SkeletonBox(
                            key: ValueKey('author_name_skeleton'),
                            width: 110,
                            height: 14,
                          ),
                          error: (_, _) => Text(
                            AppStrings.recordedBy,
                            style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p2),
                    Text(
                      Formatters.formatDateTime(note.createdAt),
                      style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (note.appointmentId != null)
                IconButton(
                  tooltip: AppStrings.viewAppointment,
                  icon: const Icon(Icons.event_note_outlined, size: AppSizes.iconSmall),
                  onPressed: () => context.push(AppRoutes.appointmentDetail.replaceFirst(':id', note.appointmentId!)),
                ),
              RecordActionMenu<String>(
                tooltip: AppStrings.moreActions,
                actions: const [
                  RecordMenuAction('edit', AppStrings.edit, Icons.edit_outlined),
                  RecordMenuAction('delete', AppStrings.delete, Icons.delete_outline, destructive: true),
                ],
                onSelected: (action) async {
                  if (ref.read(currentUserProvider).value?.isActive != true) return;
                  if (action == 'edit') {
                    await WorkspaceNoteEditor.show(context, note.patientId, note: note);
                  } else {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => const ConfirmationDialog(
                        title: AppStrings.deleteNote,
                        message: AppStrings.confirmDeleteNote,
                        confirmLabel: AppStrings.delete,
                        isDestructive: true,
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    final result = await ref.read(patientNoteActionsControllerProvider.notifier).delete(note);
                    if (!context.mounted) return;
                    result.when(
                      success: (_) => AppSnackbar.show(context, message: AppStrings.noteDeleted),
                      failure: (e) => AppSnackbar.show(
                        context,
                        message: AppStrings.fromKey(e.userMessageKey),
                        variant: AppSnackbarVariant.error,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p10),
          SelectableText(note.noteText, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
