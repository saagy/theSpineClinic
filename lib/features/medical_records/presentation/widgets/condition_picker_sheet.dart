library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/medical_records/domain/body_region.dart';
import 'package:spine_clinic_app/features/medical_records/domain/condition_catalog.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/condition_catalog_providers.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/region_condition_tile.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/region_filter_dropdown.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// Modal bottom sheet to search and multi-select conditions from the catalog.
class ConditionPickerSheet extends ConsumerStatefulWidget {
  const ConditionPickerSheet({
    super.key,
    required this.selectedConditionIds,
  });

  final Set<String> selectedConditionIds;

  static Future<List<ConditionCatalog>?> show(
    BuildContext context, {
    required Set<String> initialSelectedIds,
  }) {
    return AppBottomSheet.show<List<ConditionCatalog>>(
      context: context,
      title: AppStrings.selectInjuries,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (ctx, _) => ConditionPickerSheet(
        selectedConditionIds: initialSelectedIds,
      ),
    );
  }

  @override
  ConsumerState<ConditionPickerSheet> createState() =>
      _ConditionPickerSheetState();
}

class _ConditionPickerSheetState extends ConsumerState<ConditionPickerSheet> {
  late final Set<String> _selectedIds;
  String _searchQuery = '';
  BodyRegion? _selectedRegion;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.selectedConditionIds);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = query.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(conditionCatalogProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: AppSearchBar(
            hintText: AppStrings.search,
            onChanged: _onSearchChanged,
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
          child: RegionFilterDropdown(
            selectedRegion: _selectedRegion,
            onChanged: (region) => setState(() => _selectedRegion = region),
          ),
        ),
        const SizedBox(height: AppSizes.p8),
        Expanded(
          child: catalogAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSizes.p16),
              child: SkeletonTileList(count: 6),
            ),
            error: (err, _) => Center(child: Text(err.toString())),
            data: (allConditions) {
              final filtered = allConditions.where((c) {
                final matchRegion = _selectedRegion == null ||
                    c.region == _selectedRegion;
                final matchQuery = _searchQuery.isEmpty ||
                    c.conditionName.toLowerCase().contains(_searchQuery) ||
                    c.region.displayName.toLowerCase().contains(_searchQuery);
                return matchRegion && matchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return const EmptyState(
                  message: AppStrings.noMatchingConditions,
                  icon: Icons.search_off_rounded,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final condition = filtered[index];
                  final isSelected = _selectedIds.contains(condition.id);

                  return RegionConditionTile(
                    condition: condition,
                    isSelected: isSelected,
                    onToggle: () {
                      setState(() {
                        if (isSelected) {
                          _selectedIds.remove(condition.id);
                        } else {
                          _selectedIds.add(condition.id);
                        }
                      });
                    },
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSizes.p16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: AppButton(
            labelText: _selectedIds.isEmpty
                ? AppStrings.apply
                : '${AppStrings.apply} (${_selectedIds.length})',
            onPressed: () {
              final allConditions = catalogAsync.value ?? [];
              final selected = allConditions
                  .where((c) => _selectedIds.contains(c.id))
                  .toList();
              Navigator.of(context).pop(selected);
            },
          ),
        ),
      ],
    );
  }
}
