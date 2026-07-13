/// Receptionist appointments dashboard with Today / Booking / All tabs.
///
/// Today tab: stats strip, search bar, and appointments grouped by status.
/// Booking tab: due-patient and doctor-schedule workboard.
/// All tab: full appointment archive with search, sort, and filter controls.
///
/// Admin users see a branch selector dropdown in the header to toggle between
/// "All Branches" and individual clinic locations.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/features/admin/presentation/branch_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_tab.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_booking_tab.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointments_header.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_today_tab.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

/// Main receptionist dashboard with Today, Booking, and All tabs.
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

  bool _allFetched = false;

  void _onTabChanged() {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            ReceptionistAppointmentsHeader(clinic: clinic, isAdmin: isAdmin),
            ReceptionistAppointmentsTabStrip(controller: _tabCtrl),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  ReceptionistTodayTab(
                    state: state,
                    searchQuery: _searchQuery,
                    onSearchChanged: (q) => setState(() => _searchQuery = q),
                    onRefresh: () => ref
                        .read(receptionistAppointmentsProvider.notifier)
                        .loadToday(),
                    onStatusChanged: () => ref
                        .read(receptionistAppointmentsProvider.notifier)
                        .loadToday(),
                  ),
                  const ReceptionistBookingTab(),
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
