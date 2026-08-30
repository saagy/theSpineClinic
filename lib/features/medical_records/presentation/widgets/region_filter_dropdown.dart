library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';

/// Modern styled dropdown to filter conditions by anatomical body region.
class RegionFilterDropdown extends StatelessWidget {
  const RegionFilterDropdown({
    super.key,
    required this.selectedRegion,
    required this.onChanged,
  });

  final BodyRegion? selectedRegion;
  final ValueChanged<BodyRegion?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p2,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BodyRegion?>(
          value: selectedRegion,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: cs.primary,
          ),
          dropdownColor: cs.surface,
          borderRadius: BorderRadius.circular(AppSizes.r12),
          items: [
            const DropdownMenuItem<BodyRegion?>(
              value: null,
              child: Row(
                children: [
                  Icon(Icons.category_outlined, size: 18),
                  SizedBox(width: AppSizes.p8),
                  Text(AppStrings.allBodyRegions),
                ],
              ),
            ),
            ...BodyRegion.values.map(
              (region) => DropdownMenuItem<BodyRegion?>(
                value: region,
                child: Row(
                  children: [
                    Icon(Icons.accessibility_new_outlined, size: 18),
                    SizedBox(width: AppSizes.p8),
                    Text(region.displayName),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
