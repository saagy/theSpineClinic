import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// Renders a list/grid of uploaded documents and an upload button for a patient.
class PatientTabDocuments extends ConsumerWidget {
  /// Creates a [PatientTabDocuments].
  const PatientTabDocuments({super.key, required this.patient});

  /// The patient entity.
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isDoctor = user?.role == UserRole.doctor;

    // Mock documents data.
    final List<Map<String, dynamic>> mockDocs = [
      {
        'name': 'x-ray-lumbar.pdf',
        'date': '2026-06-01',
        'size': '2.4 MB',
      },
      {
        'name': 'mri-report.pdf',
        'date': '2026-05-25',
        'size': '4.1 MB',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isDoctor) ...[
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: AppButton(
              labelText: AppStrings.upload,
              onPressed: () {
                // To be wired to FilePicker in a future phase.
              },
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
        Expanded(
          child: mockDocs.isEmpty
              ? const EmptyState(
                  message: 'No documents uploaded yet',
                  icon: Icons.folder_open_rounded,
                )
              : ListView.builder(
                  itemCount: mockDocs.length,
                  itemBuilder: (context, index) {
                    final doc = mockDocs[index];
                    return DataListTile(
                      title: doc['name'] as String,
                      subtitle: '${doc['date']} · ${doc['size']}',
                      leading: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: AppColors.error,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.download_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          // To open the file URL in a future phase.
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
