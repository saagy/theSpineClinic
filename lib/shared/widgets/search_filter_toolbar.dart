import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_search_field.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_filter_button.dart';

class SearchFilterToolbar extends StatelessWidget {
  const SearchFilterToolbar({
    super.key,
    required this.onSearch,
    required this.onFilter,
    required this.activeCount,
    this.hint,
    this.query,
  });
  final ValueChanged<String> onSearch;
  final VoidCallback onFilter;
  final int activeCount;
  final String? hint;
  final String? query;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: AppointmentSearchField(onChanged: onSearch, hintText: hint, initialValue: query),
      ),
      const SizedBox(width: AppSizes.p8),
      ReceptionistAllFilterButton(activeFiltersCount: activeCount, onTap: onFilter),
    ],
  );
}
