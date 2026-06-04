import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_badge.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';

/// Renders a chronological list of appointments for a patient.
class PatientTabAppointments extends ConsumerWidget {
  /// Creates a [PatientTabAppointments].
  const PatientTabAppointments({super.key, required this.patient});

  /// The patient entity.
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;

    // Mock appointments data.
    final List<Map<String, dynamic>> mockAppointments = [
      {
        'time': '2026-06-05 10:00 AM',
        'type': AppStrings.session,
        'status': AppStrings.scheduled,
        'doctors': 'Dr. Hassan Aly',
        'isReplacement': false,
      },
      {
        'time': '2026-06-05 11:30 AM',
        'type': AppStrings.gehazShadFakarat,
        'status': AppStrings.scheduled,
        'doctors': 'Dr. Khaled Amin',
        'isReplacement': true,
        'replacedDoctor': 'Dr. Hassan Aly',
      },
      {
        'time': '2026-06-03 04:00 PM',
        'type': AppStrings.session,
        'status': AppStrings.completed,
        'doctors': 'Dr. Khaled Amin',
        'isReplacement': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDoctor) ...[
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: AppButton(
              labelText: AppStrings.bookAppointment,
              onPressed: () {
                // To be wired to NewAppointmentScreen in a future phase.
              },
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
        Expanded(
          child: ListView.builder(
            itemCount: mockAppointments.length,
            itemBuilder: (context, index) {
              final apt = mockAppointments[index];
              final bool isRep = apt['isReplacement'] as bool;
              final String subtitle = isRep
                  ? '${apt['doctors']} (Covering ${apt['replacedDoctor']})'
                  : apt['doctors'] as String;

              return DataListTile(
                title: apt['time'] as String,
                subtitle: subtitle,
                leading: AppBadge(
                  label: apt['type'] as String,
                  textColor: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                ),
                trailing: _buildStatusBadge(apt['status'] as String),
                onTap: () {
                  // To be wired to AppointmentDetailScreen in a future phase.
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color txtColor = AppColors.textSecondary;
    Color bgColor = AppColors.background;

    if (status == AppStrings.scheduled) {
      txtColor = AppColors.info;
      bgColor = AppColors.infoBg;
    } else if (status == AppStrings.completed) {
      txtColor = AppColors.success;
      bgColor = AppColors.successBg;
    } else if (status == AppStrings.cancelled) {
      txtColor = AppColors.error;
      bgColor = AppColors.errorBg;
    }

    return AppBadge(
      label: status,
      textColor: txtColor,
      backgroundColor: bgColor,
    );
  }
}
