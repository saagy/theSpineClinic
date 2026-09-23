import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_linked_session_row.dart';
import 'package:spine_clinic_app/shared/widgets/stable_fade_swap.dart';

class AppointmentLinkedSessionsSection extends StatelessWidget {
  const AppointmentLinkedSessionsSection({
    super.key,
    required this.appointments,
    required this.labelStyle,
  });

  final List<Appointment> appointments;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: StableFadeSwap(
        stateKey: appointments.isEmpty ? 'empty' : 'linked',
        alignment: Alignment.topLeft,
        child: appointments.isEmpty
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
                    child: Divider(
                      color: colors.outlineVariant,
                      height: AppSizes.borderWidth,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: AppSizes.iconSmall,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: AppSizes.p6),
                      Text(
                        (appointments.length > 1
                                ? AppStrings.linkedSessions
                                : AppStrings.linkedSession)
                            .toUpperCase(),
                        style: labelStyle.copyWith(color: colors.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.p8),
                  for (final linked in appointments)
                    AppointmentLinkedSessionRow(appointment: linked),
                ],
              ),
      ),
    );
  }
}
