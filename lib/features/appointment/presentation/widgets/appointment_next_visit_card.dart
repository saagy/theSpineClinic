import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_detail_controller.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

class AppointmentNextVisitCard extends ConsumerStatefulWidget {
  const AppointmentNextVisitCard({
    super.key,
    required this.appointmentId,
    required this.patient,
  });

  final String appointmentId;
  final Patient patient;

  @override
  ConsumerState<AppointmentNextVisitCard> createState() =>
      _AppointmentNextVisitCardState();
}

class _AppointmentNextVisitCardState
    extends ConsumerState<AppointmentNextVisitCard> {
  bool _submitting = false;

  Future<void> _setDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: widget.patient.nextVisitDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: AppStrings.setNextVisit,
    );
    if (date != null) await _save(date);
  }

  Future<void> _clear() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmationDialog(
        title: AppStrings.clearNextVisit,
        message: AppStrings.stopFollowUpMessage,
        confirmLabel: AppStrings.clearNextVisit,
        isDestructive: true,
      ),
    );
    if (confirmed == true) await _save(null);
  }

  Future<void> _save(DateTime? date) async {
    setState(() => _submitting = true);
    final result = await ref
        .read(
          appointmentDetailControllerProvider(widget.appointmentId).notifier,
        )
        .updateNextVisit(date);
    if (!mounted) return;
    setState(() => _submitting = false);
    result.when(
      success: (_) => AppSnackbar.show(
        context,
        message: AppStrings.nextVisitUpdated,
        variant: AppSnackbarVariant.success,
      ),
      failure: (error) => AppSnackbar.show(
        context,
        message: AppStrings.fromKey(error.userMessageKey),
        variant: AppSnackbarVariant.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? date = widget.patient.nextVisitDate;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
      child: SectionCard(
        title: AppStrings.nextVisit,
        action: _submitting
            ? const SizedBox(
                width: AppSizes.iconDefault,
                height: AppSizes.iconDefault,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.strokeWidthThin,
                ),
              )
            : TextButton(
                onPressed: _setDate,
                child: Text(
                  date == null ? AppStrings.setNextVisit : AppStrings.change,
                ),
              ),
        child: Row(
          children: [
            const Icon(Icons.event_repeat_rounded),
            const SizedBox(width: AppSizes.p12),
            Expanded(
              child: Text(
                date == null
                    ? AppStrings.noNextVisitSet
                    : DateFormat('EEE, MMM d, yyyy').format(date),
                style: date == null
                    ? AppTextStyles.bodySecondary
                    : AppTextStyles.bodyBold,
              ),
            ),
            if (date != null)
              IconButton(
                tooltip: AppStrings.clearNextVisit,
                onPressed: _submitting ? null : _clear,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
