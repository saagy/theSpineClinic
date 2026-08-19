import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/constants/clinic_colors.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/appointment_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_actions_trailing.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';
part 'receptionist_grouped_appointment_card_header.dart';
part 'receptionist_grouped_appointment_card_individual_menu.dart';
part 'receptionist_grouped_appointment_card_menu.dart';
part 'receptionist_grouped_appointment_card_sub_row.dart';

/// Renders multiple appointments for a patient on the same day as a single,
/// unified card with a sub-session timeline and batch status options.
class ReceptionistGroupedAppointmentCard extends ConsumerStatefulWidget {
  const ReceptionistGroupedAppointmentCard({
    super.key,
    required this.patient,
    required this.items,
    this.onStatusChanged,
  });

  final Patient patient;
  final List<AppointmentWithPatient> items;
  final VoidCallback? onStatusChanged;

  @override
  ConsumerState<ReceptionistGroupedAppointmentCard> createState() =>
      _ReceptionistGroupedAppointmentCardState();
}

class _ReceptionistGroupedAppointmentCardState
    extends ConsumerState<ReceptionistGroupedAppointmentCard>
    with _ReceptionistGroupedAppointmentCardMenu {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinic = ClinicColors.of(context);
    final user = ref.watch(currentUserProvider).value;
    final bool isDocOnPatient = user?.role == UserRole.doctor &&
        (ref.watch(isDoctorAssignedToPatientProvider(widget.patient.id)).value ?? false);
    final bool isAuthorizedStaff = user != null &&
        (user.role == UserRole.receptionist ||
            user.role == UserRole.superAdmin ||
            isDocOnPatient);

    final statuses = widget.items.map((i) => i.appointment.status).toSet();
    final bool allCancelled =
        statuses.length == 1 && statuses.contains(AppointmentStatus.cancelled);
    final bool allCheckedIn =
        statuses.length == 1 && statuses.contains(AppointmentStatus.checkedIn);
    final bool hasScheduled = statuses.contains(AppointmentStatus.scheduled);
    final bool hasCheckedIn = statuses.contains(AppointmentStatus.checkedIn);
    final bool hasCancellable =
        statuses.any((s) => s != AppointmentStatus.cancelled);

    final bool isAnyPastScheduled = widget.items.any((item) {
      final t = item.appointment.scheduledAt.toLocal();
      return item.appointment.status == AppointmentStatus.scheduled &&
          DateUtils.dateOnly(t).isBefore(DateUtils.dateOnly(DateTime.now()));
    });

    final sortedItems = List<AppointmentWithPatient>.from(widget.items)
      ..sort((a, b) =>
          a.appointment.scheduledAt.compareTo(b.appointment.scheduledAt));
    final timeStr = DateFormat('h:mm a')
        .format(sortedItems.first.appointment.scheduledAt.toLocal());

    final Color cardBg = isAnyPastScheduled
        ? clinic.warningContainer
        : (allCheckedIn ? clinic.checkedInContainer : theme.colorScheme.surface);
    final Color cardBorder = isAnyPastScheduled
        ? clinic.warning
        : (allCheckedIn ? clinic.checkedInOutline : theme.colorScheme.outline);

    final Widget card = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(
          color: cardBorder,
          width: AppSizes.borderWidth,
        ),
        boxShadow: [clinic.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupedCardHeader(
                patientName: widget.patient.fullName,
                timeStr: timeStr,
                allCancelled: allCancelled,
                trailing: isAuthorizedStaff
                    ? buildGroupContextMenu(
                        context: context,
                        items: widget.items,
                        hasScheduled: hasScheduled,
                        hasCheckedIn: hasCheckedIn,
                        allCancelled: allCancelled,
                        hasCancellable: hasCancellable,
                      )
                    : null,
              ),
              const SizedBox(height: AppSizes.p12),
              Divider(
                color: isAnyPastScheduled
                    ? clinic.warning.withAlpha(80)
                    : (allCheckedIn
                        ? clinic.checkedInOutline.withAlpha(120)
                        : theme.colorScheme.outline),
                height: 1,
                thickness: 0.5,
              ),
              const SizedBox(height: AppSizes.p8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedItems.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSizes.p8),
                itemBuilder: (context, idx) {
                  final item = sortedItems[idx];
                  return _GroupedSubAppointmentRow(
                    item: item,
                    isAuthorizedStaff: isAuthorizedStaff,
                    onStatusChanged: widget.onStatusChanged,
                    onShowStatusMenu: showIndividualStatusMenu,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p16,
        vertical: AppSizes.p4,
      ),
      child: allCancelled ? Opacity(opacity: 0.6, child: card) : card,
    );
  }
}
