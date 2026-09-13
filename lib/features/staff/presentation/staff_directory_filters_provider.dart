import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_list_filter_models.dart';

part 'staff_directory_filters_provider.g.dart';

class StaffDirectoryFilterState {
  const StaffDirectoryFilterState({
    this.query = '',
    this.filters = const StaffListFilters(),
    this.sort = StaffSortOption.nameAsc,
  });
  final String query;
  final StaffListFilters filters;
  final StaffSortOption sort;
  StaffDirectoryFilterState copyWith({
    String? query,
    StaffListFilters? filters,
    StaffSortOption? sort,
  }) => StaffDirectoryFilterState(
    query: query ?? this.query,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
  );
}

@Riverpod(keepAlive: true)
class StaffDirectoryFilters extends _$StaffDirectoryFilters {
  @override
  StaffDirectoryFilterState build() => const StaffDirectoryFilterState();
  void search(String query) => state = state.copyWith(query: query);
  void filter(StaffListFilters filters) => state = state.copyWith(filters: filters);
  void sort(StaffSortOption sort) => state = state.copyWith(sort: sort);
}
