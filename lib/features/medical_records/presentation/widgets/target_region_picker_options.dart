import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_target_region.dart';
import 'package:spine_clinic_app/shared/widgets/form_field_label.dart';

/// Searchable option list shared by the compact and desktop target-region pickers.
class TargetRegionPickerOptions extends StatefulWidget {
  const TargetRegionPickerOptions({
    super.key,
    required this.value,
    required this.regions,
    this.scrollController,
  });

  final String value;
  final List<ModalityTargetRegion> regions;
  final ScrollController? scrollController;

  @override
  State<TargetRegionPickerOptions> createState() =>
      _TargetRegionPickerOptionsState();
}

class _TargetRegionPickerOptionsState extends State<TargetRegionPickerOptions> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<ModalityTargetRegion> visibleRegions = widget.regions
        .where(
          (region) => region.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.targetRegionOptions(widget.regions.length),
          style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSizes.p12),
        TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (query) => setState(() => _query = query),
          decoration:
              formInputDecoration(
                context,
                hint: AppStrings.searchTargetRegions,
              ).copyWith(
                prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: AppStrings.clearTargetRegionSearch,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
        ),
        const SizedBox(height: AppSizes.p12),
        SizedBox(
          height: AppSizes.targetRegionPickerListHeight,
          child: visibleRegions.isEmpty
              ? Center(
                  child: Text(
                    AppStrings.noTargetRegionsFound,
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: widget.scrollController,
                  itemCount: visibleRegions.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: AppSizes.p2, color: cs.outlineVariant),
                  itemBuilder: (context, index) {
                    final ModalityTargetRegion region = visibleRegions[index];
                    return _TargetRegionOption(
                      region: region,
                      selected: region.name == widget.value,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TargetRegionOption extends StatelessWidget {
  const _TargetRegionOption({required this.region, required this.selected});

  final ModalityTargetRegion region;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.secondaryContainer : cs.surface,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(region.name),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p12,
            vertical: AppSizes.p8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  region.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: selected ? cs.onSecondaryContainer : cs.onSurface,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, color: cs.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
