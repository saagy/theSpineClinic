/// Management screen listing all appointments across doctors and branches.
///
/// Accessible to admin and receptionist roles only. Supports combinable
/// filters: date range, doctor, branch, status, and patient name search.
/// Infinite-scroll pagination loads 30 items at a time.
///
/// Rule 9 — handles loading, error, empty, and data states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_type.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_filter_content.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/shared/widgets/app_search_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_filter_bar.dart';
import 'package:spine_clinic_app/shared/widgets/sort_options_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/active_filter_chips_row.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
// all_appointments_screen.dart imports
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';

/// Full-screen management view of all appointments with infinite-scroll pagination.
class AllAppointmentsScreen extends ConsumerStatefulWidget {
  /// Creates an [AllAppointmentsScreen].
  const AllAppointmentsScreen({super.key});

  @override
  ConsumerState<AllAppointmentsScreen> createState() => _AllAppointmentsScreenState();
}

enum AppointmentSortOption {
  dateNewest,
  dateOldest;

  String get displayLabel => switch (this) {
    AppointmentSortOption.dateNewest => 'Date (Newest)',
    AppointmentSortOption.dateOldest => 'Date (Oldest)',
  };

  String get buttonLabel => switch (this) {
    AppointmentSortOption.dateNewest => 'Date ↓',
    AppointmentSortOption.dateOldest => 'Date ↑',
  };
}

class _AllAppointmentsScreenState extends ConsumerState<AllAppointmentsScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  final Set<int> _animatedIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(allAppointmentsProvider.notifier).loadMore();
    }
  }

  Future<void> _showSortSheet() async {
    final notifier = ref.read(allAppointmentsProvider.notifier);
    final currentAscending = notifier.isAscending;
    // Map notifier state to UI enum
    AppointmentSortOption currentSort;
    if (currentAscending) {
      currentSort = AppointmentSortOption.dateOldest;
    } else {
      currentSort = AppointmentSortOption.dateNewest;
    }

    final selected = await SortOptionsSheet.show<AppointmentSortOption>(
      context: context,
      title: 'Sort Options',
      options: AppointmentSortOption.values
          .map((o) => SortOption(
                value: o,
                label: o.displayLabel,
                buttonLabel: o.buttonLabel,
              ))
          .toList(),
      selected: currentSort,
    );
    if (selected != null && mounted) {
      notifier.setSortAscending(
        selected == AppointmentSortOption.dateOldest,
      );
    }
  }

  String get _sortButtonLabel {
    return ref.read(allAppointmentsProvider.notifier).isAscending
        ? 'Date ↑'
        : 'Date ↓';
  }

  List<ActiveFilterChip> get _activeChips {
    final chips = <ActiveFilterChip>[];
    final n = ref.read(allAppointmentsProvider.notifier);
    final user = ref.watch(currentUserProvider).value;
    final bool isReceptionist = user?.role == UserRole.receptionist;

    // Date range — single combined chip
    final bool hasDateFrom = n.dateFrom != null;
    final bool hasDateTo = n.dateTo != null;
    if (hasDateFrom || hasDateTo) {
      String label;
      if (hasDateFrom && hasDateTo) {
        final displayTo = n.dateTo!.subtract(const Duration(days: 1));
        label = '${Formatters.formatDateShort(n.dateFrom!)} – ${Formatters.formatDateShort(displayTo)}';
      } else if (hasDateFrom) {
        label = 'From ${Formatters.formatDateShort(n.dateFrom!)}';
      } else {
        final displayTo = n.dateTo!.subtract(const Duration(days: 1));
        label = 'To ${Formatters.formatDateShort(displayTo)}';
      }
      chips.add(ActiveFilterChip(
        label: label,
        onRemove: () {
          n.setDateFrom(null);
          n.setDateTo(null);
        },
      ));
    }
    // Doctor
    if (n.doctorId != null) {
      final doctors = ref.watch(activeDoctorsProvider).value ?? [];
      final doctor = doctors.cast<Staff?>().firstWhere(
            (d) => d!.id == n.doctorId,
            orElse: () => null,
          );
      chips.add(ActiveFilterChip(
        label: doctor?.fullName ?? 'Doctor',
        onRemove: () => n.setDoctorFilter(null),
      ));
    }
    // Clinic — hidden for receptionists (branch is enforced, not a choice)
    if (n.clinic != null && !isReceptionist) {
      final clinic = ClinicLocation.values.cast<ClinicLocation?>().firstWhere(
            (c) => c!.dbValue == n.clinic,
            orElse: () => null,
          );
      chips.add(ActiveFilterChip(
        label: clinic?.displayLabel ?? n.clinic!,
        onRemove: () => n.setClinicFilter(null),
      ));
    }
    // Status
    if (n.status != null) {
      final status = AppointmentStatus.values.cast<AppointmentStatus?>().firstWhere(
            (s) => s!.dbValue == n.status,
            orElse: () => null,
          );
      chips.add(ActiveFilterChip(
        label: status?.displayLabel ?? n.status!,
        onRemove: () => n.setStatusFilter(null),
      ));
    }
    // Type
    if (n.type != null) {
      final type = AppointmentType.values.cast<AppointmentType?>().firstWhere(
            (t) => t!.dbValue == n.type,
            orElse: () => null,
          );
      chips.add(ActiveFilterChip(
        label: type?.displayLabel ?? n.type!,
        onRemove: () => n.setTypeFilter(null),
      ));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final Staff? user = ref.watch(currentUserProvider).value;
    if (user == null || (user.role != UserRole.superAdmin && user.role != UserRole.receptionist)) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const ErrorView(
          exception: UnknownException(message: AppStrings.accessDeniedAdminReceptionOnly),
        ),
      );
    }

    final AsyncValue<List<AppointmentWithPatient>> appointmentsAsync =
        ref.watch(allAppointmentsProvider);
    if (appointmentsAsync.isLoading && appointmentsAsync.value == null) {
      _animatedIndices.clear();
    }
    final AllAppointmentsNotifier notifier = ref.read(allAppointmentsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(AppStrings.allAppointments, style: AppTextStyles.headingSmall),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p4,
            ),
            child: AppSearchBar(
              hintText: AppStrings.searchByPatientNameHint,
              onChanged: notifier.searchPatient,
            ),
          ),
          SortFilterBar(
            sortLabel: 'Sort: $_sortButtonLabel',
            onSortTap: _showSortSheet,
            activeFilterCount: _activeChips.length,
            onFilterTap: () => _openFilterSheet(context),
          ),
          ActiveFilterChipsRow(
            chips: _activeChips,
            onClearAll: () => ref.read(allAppointmentsProvider.notifier).clearAll(),
          ),
          if (appointmentsAsync.value != null && !appointmentsAsync.isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p8, AppSizes.p20, AppSizes.p4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Total Appointments: ${ref.watch(allAppointmentsProvider.notifier).totalCount}',
                  style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          Expanded(child: _buildBody(appointmentsAsync)),
        ],
      ),
    );
  }

  Widget _buildBody(AsyncValue<List<AppointmentWithPatient>> async) {
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (Object error, StackTrace _) => ErrorView(
        exception: UnknownException(message: '$error'),
        onRetry: () => ref.read(allAppointmentsProvider.notifier).clearAll(),
      ),
      data: (List<AppointmentWithPatient> items) {
        if (items.isEmpty) {
          return const EmptyState(
            message: AppStrings.noAppointmentsFound,
            icon: Icons.event_busy_rounded,
          );
        }
        final bool loadingMore = ref.watch(isLoadingMoreProvider);
        final List<_ListItem> listItems = _buildListItems(items);

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(allAppointmentsProvider.notifier).refresh();
            try {
              await ref.read(allAppointmentsProvider.future);
            } catch (_) {}
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollCtrl,
            padding: const EdgeInsets.only(bottom: AppSizes.p32),
            itemCount: listItems.length + (loadingMore ? 1 : 0),
            itemBuilder: (_, int index) {
              if (index == listItems.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.p16),
                  child: Center(
                    child: SizedBox(
                      width: AppSizes.iconDefault,
                      height: AppSizes.iconDefault,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSizes.strokeWidthThin,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }
              final _ListItem listItem = listItems[index];
              if (listItem is _HeaderItem) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8),
                  child: Text(
                    listItem.title,
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              final AppointmentWithPatient item = (listItem as _AppointmentItem).item;
              return AnimatedListItem(
                index: index,
                animatedIndices: _animatedIndices,
                child: ReceptionistAppointmentCard(
                  key: ValueKey(item.appointment.id),
                  item: item,
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<_ListItem> _buildListItems(List<AppointmentWithPatient> items) {
    final List<_ListItem> listItems = [];
    String? lastHeader;

    for (final item in items) {
      final date = item.appointment.scheduledAt.toLocal();
      final header = _getGroupHeader(date);
      if (header != lastHeader) {
        listItems.add(_HeaderItem(header));
        lastHeader = header;
      }
      listItems.add(_AppointmentItem(item));
    }
    return listItems;
  }

  String _getGroupHeader(DateTime date) {
    final DateTime localDate = date.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime comparisonDate = DateTime(localDate.year, localDate.month, localDate.day);

    final int difference = today.difference(comparisonDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == -1) return 'Tomorrow';
    // Everything else: absolute day name + abbreviated month + day
    return DateFormat('EEEE, MMM d').format(localDate);
  }

  void _openFilterSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Advanced Filters',
      builder: (context, scrollController) => AppointmentFilterContent(
        scrollController: scrollController,
      ),
    );
  }
}

sealed class _ListItem {}

class _HeaderItem extends _ListItem {
  _HeaderItem(this.title);
  final String title;
}

class _AppointmentItem extends _ListItem {
  _AppointmentItem(this.item);
  final AppointmentWithPatient item;
}
