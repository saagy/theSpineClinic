/// Receptionist appointments dashboard with Today / Upcoming tabs.
///
/// Today tab: stats strip, search bar, and appointments grouped by status.
/// Upcoming tab: future appointments grouped by date.
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
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_tab.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_upcoming_tab.dart';
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
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receptionistAppointmentsProvider.notifier).loadToday();
    });
  }

  bool _upcomingFetched = false;

  void _onTabChanged() {
    if (_tabCtrl.index == 1 && !_upcomingFetched) {
      _upcomingFetched = true;
      ref.read(receptionistAppointmentsProvider.notifier).loadUpcoming();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(clinic: clinic),
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

/// Header row: clinic name (left) + formatted today's date (right).
class _Header extends StatelessWidget {
  const _Header({required this.clinic});
  final ClinicLocation clinic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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

/// Material tab strip: "Today" (default) and "Upcoming".
class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: TabBar(
        controller: controller,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.bodyBold,
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2,
        tabs: const [Tab(text: 'Today'), Tab(text: 'Upcoming')],
      ),
    );
  }
}
