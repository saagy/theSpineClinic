import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/patient/domain/patient.dart';
import 'package:spine_clinic_app/shared/widgets/data_list_tile.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// Renders completed medical visit logs and notes for a patient.
class PatientTabRecords extends ConsumerWidget {
  /// Creates a [PatientTabRecords].
  const PatientTabRecords({super.key, required this.patient});

  /// The patient entity.
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock medical records data.
    final List<Map<String, dynamic>> mockRecords = [
      {
        'date': '2026-06-01',
        'doctor': 'Dr. Hassan Aly',
        'notes': 'Patient reports significant improvement in lower back pain. Continued physical therapy recommended.',
      },
      {
        'date': '2026-05-25',
        'doctor': 'Dr. Khaled Amin',
        'notes': 'Initial evaluation complete. Mild lumbar herniation noted. Scheduled for decompression therapy.',
      },
    ];

    if (mockRecords.isEmpty) {
      return const EmptyState(
        message: 'No visit notes recorded yet',
        icon: Icons.history_edu_rounded,
      );
    }

    return ListView.builder(
      itemCount: mockRecords.length,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
      itemBuilder: (context, index) {
        final record = mockRecords[index];
        return DataListTile(
          title: record['date'] as String,
          subtitle: '${record['doctor']} · ${record['notes']}',
          leading: const Icon(
            Icons.article_outlined,
            color: AppColors.textSecondary,
          ),
          onTap: () {
            // To be wired to VisitDetailScreen in a future phase.
          },
        );
      },
    );
  }
}
