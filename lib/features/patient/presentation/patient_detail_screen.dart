import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/patient/presentation/patient_providers.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/patient_workspace_body.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_page_skeleton.dart';
import 'package:spine_clinic_app/features/patient/presentation/widgets/workspace_patient_menu.dart';
import 'package:spine_clinic_app/shared/widgets/app_back_button.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';

/// Role-aware modern 2026 patient workspace screen.
class PatientDetailScreen extends ConsumerStatefulWidget {
  const PatientDetailScreen({super.key, required this.patientId});
  final String patientId;

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  bool _showPatientTitle = false;

  void _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return;
    final show = notification.metrics.pixels > AppSizes.p40;
    if (show != _showPatientTitle) {
      setState(() => _showPatientTitle = show);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAccess = ref.watch(canAccessPatientProvider(widget.patientId)).value ?? false;
    final patient = canAccess ? ref.watch(patientDetailProvider(widget.patientId)).value : null;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
        title: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showPatientTitle && patient != null
                ? Text(
                    patient.fullName,
                    key: const ValueKey('patient_appbar_name'),
                    style: AppTextStyles.headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text(
                    AppStrings.patientRecord,
                    key: ValueKey('patient_appbar_default'),
                    style: AppTextStyles.headingSmall,
                  ),
          ),
        ),
        actions: canAccess
            ? [
                WorkspacePatientEditAction(patientId: widget.patientId),
                WorkspacePatientMenu(patientId: widget.patientId),
              ]
            : null,
      ),
      body: SafeArea(
        top: false,
        child: RecordAsync(
          skeleton: const WorkspacePageSkeleton(),
          value: ref.watch(canAccessPatientProvider(widget.patientId)),
          onRetry: () => ref.invalidate(canAccessPatientProvider(widget.patientId)),
          data: (allowed) {
            if (!allowed) {
              return const Center(child: RecordMessage(message: AppStrings.errorDatabasePermissionDenied));
            }
            return RecordAsync(
              skeleton: const WorkspacePageSkeleton(),
              value: ref.watch(patientDetailProvider(widget.patientId)),
              onRetry: () => ref.invalidate(patientDetailProvider(widget.patientId)),
              data: (patient) => PatientWorkspaceBody(patient: patient, onScroll: _onScroll),
            );
          },
        ),
      ),
    );
  }
}
