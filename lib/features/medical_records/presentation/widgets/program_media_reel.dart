library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/program_media_card.dart';
import 'package:spine_clinic_app/features/patient/domain/patient_document.dart';

/// Space-efficient horizontal media reel for imaging attachments and scans.
class ProgramMediaReel extends StatelessWidget {
  const ProgramMediaReel({
    super.key,
    required this.documents,
    required this.onOpenDocument,
  });

  final List<PatientDocument> documents;
  final void Function(int initialIndex) onOpenDocument;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 16,
                    color: cs.primary,
                  ),
                  const SizedBox(width: AppSizes.p6),
                  Text(
                    AppStrings.imagingAttachments,
                    style: AppTextStyles.captionBold.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.p8,
                  vertical: AppSizes.p2,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: Text(
                  AppStrings.scanCountLabel(documents.length),
                  style: AppTextStyles.captionBold.copyWith(
                    color: cs.onPrimaryContainer,
                    fontSize: AppSizes.fontSizeXs,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p8),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: documents.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSizes.p10),
              itemBuilder: (context, index) {
                final doc = documents[index];
                return ProgramMediaCard(
                  document: doc,
                  onTap: () => onOpenDocument(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
