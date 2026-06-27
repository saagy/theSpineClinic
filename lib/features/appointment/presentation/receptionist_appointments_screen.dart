/// Receptionist appointments dashboard with Today / Upcoming / All tabs.
///
/// Today tab: stats strip, search bar, and appointments grouped by status.
/// Upcoming tab: future appointments grouped by date.
/// All tab: full appointment archive with search, sort, and filter controls.
///
/// Admin users see a branch selector dropdown in the header to toggle between
/// "All Branches" and individual clinic locations.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_tab.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_tab.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_upcoming_tab.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/patient/domain/clinic_location.dart';

/// Main receptionist dashboard with Today / Upcoming tabs.
class ReceptionistAppointmentsScreen extends ConsumerStatefulWidget {
  const ReceptionistAppointmentsScreen({super.key});

  @override
  ConsumerState<ReceptionistAppointmentsScreen> createState() =>
      _ReceptionistAppointmentsScreenState();
}

class _ReceptionistAppointmentsScreenState
    extends ConsumerState<ReceptionistAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receptionistAppointmentsProvider.notifier).loadToday();
    });
  }

  bool _upcomingFetched = false;
  bool _allFetched = false;

  void _onTabChanged() {
    if (_tabCtrl.index == 1 && !_upcomingFetched) {
      _upcomingFetched = true;
      ref.read(receptionistAppointmentsProvider.notifier).loadUpcoming();
    }
    if (_tabCtrl.index == 2 && !_allFetched) {
      _allFetched = true;
      ref.read(allAppointmentsProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receptionistAppointmentsProvider);
    final clinic = ref.watch(activeBranchProvider);
    final user = ref.watch(currentUserProvider).value;
    final isAdmin = user?.role == UserRole.superAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(clinic: clinic, isAdmin: isAdmin),
            _TabStrip(controller: _tabCtrl),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  ReceptionistTodayTab(
                    state: state,
                    searchQuery: _searchQuery,
                    onSearchChanged: (q) => setState(() => _searchQuery = q),
                    onRefresh: () =>
                        ref.read(receptionistAppointmentsProvider.notifier).loadToday(),
                    onStatusChanged: () =>
                        ref.read(receptionistAppointmentsProvider.notifier).loadToday(),
                  ),
                  ReceptionistUpcomingTab(
                    state: state,
                    onStatusChanged: () =>
                        ref.read(receptionistAppointmentsProvider.notifier).loadUpcoming(),
                    onRefresh: () async => ref
                        .read(receptionistAppointmentsProvider.notifier)
                        .loadUpcoming(),
                  ),
                  ReceptionistAllTab(
                    onStatusChanged: () =>
                        ref.read(allAppointmentsProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header row: clinic name (or branch selector for admins) + date.
class _Header extends StatelessWidget {
  const _Header({required this.clinic, required this.isAdmin});
  final ClinicLocation clinic;
  final bool isAdmin;

  static const Map<String, ClinicLocation> _dbToEnum = {
    'tagamoa': ClinicLocation.tagamoa,
    'masr_elgedida': ClinicLocation.masrElgedida,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (isAdmin)
            _BranchDropdown(clinic: clinic)
          else
            Text(clinic.displayLabel,
                style: AppTextStyles.headingMedium
                    .copyWith(color: AppColors.textPrimary)),
          Text(DateFormat('E, MMM d').format(DateTime.now()),
              style: AppTextStyles.bodySecondary),
        ],
      ),
    );
  }
}

/// Branch selector dropdown for admin users.
///
/// Lets admins toggle between "All Branches" (null clinic filter) and
/// each individual clinic. Selection updates the all-appointments filter
/// and the active branch for Today/Upcoming tabs.
class _BranchDropdown extends ConsumerWidget {
  const _BranchDropdown({required this.clinic});
  final ClinicLocation clinic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminBranch = ref.watch(adminBranchFilterProvider);
    final String display = adminBranch == null
        ? 'All Branches'
        : _Header._dbToEnum[adminBranch]?.displayLabel ?? clinic.displayLabel;

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      padding: EdgeInsets.zero,
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSizes.r12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(display,
              style: AppTextStyles.headingMedium
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(width: AppSizes.p4),
          const Icon(Icons.arrow_drop_down_rounded,
              color: AppColors.textSecondary),
        ],
      ),
      onSelected: (String value) {
        if (value == '__all__') {
          ref.read(adminBranchFilterProvider.notifier).set(null);
          ref.read(allAppointmentsProvider.notifier).setClinicFilter(null);
        } else {
          final branch = _Header._dbToEnum[value];
          if (branch != null) {
            ref.read(adminBranchFilterProvider.notifier).set(value);
            ref.read(allAppointmentsProvider.notifier).setClinicFilter(value);

          }
        }
        // Refresh Today and Upcoming tabs for the selected branch.
        ref.read(receptionistAppointmentsProvider.notifier).loadToday();
        ref.read(receptionistAppointmentsProvider.notifier).loadUpcoming();
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: '__all__',
          child: Text('All Branches',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary)),
        ),
        ...ClinicLocation.values.map((loc) => PopupMenuItem<String>(
              value: loc.dbValue,
              child: Text(loc.displayLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary)),
            )),
      ],
    );
  }
}

/// Material tab strip: "Today", "Upcoming", and "All".
class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: controller,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyBold,
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        tabs: const [Tab(text: 'Today'), Tab(text: 'Upcoming'), Tab(text: 'All')],
      ),
    );
  }
}
