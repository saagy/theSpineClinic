import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/staff.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_assignments.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_details_providers.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_employment_section.dart';
import 'package:spine_clinic_app/features/staff/presentation/widgets/staff_profile_sections.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';
import 'package:spine_clinic_app/shared/widgets/record_surface.dart';

const _s = AppStrings.staffSchedule;

/// Read-only profile of one staff member: who they are, how to reach them,
/// where and when they work, and their employment details. Super admins
/// get Edit; head receptionists only read.
class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Staff? viewer = ref.watch(currentUserProvider).value;
    final AsyncValue<Staff> staff = ref.watch(staffProfileProvider(staffId));
    final StaffAssignments assignments = ref.watch(staffAssignmentsProvider).value ?? StaffAssignments.none;
    final Staff? loaded = staff.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(_s.profileTitle),
        actions: [
          if (loaded != null && canEditStaffRecords(viewer))
            Padding(
              padding: const EdgeInsets.only(right: AppSizes.p8),
              child: TextButton.icon(
                onPressed: () => context.push(AppRoutes.staffForm, extra: loaded),
                icon: const Icon(Icons.edit_outlined, size: AppSizes.iconSmall),
                label: Text(_s.edit),
              ),
            ),
        ],
      ),
      body: staff.when(
        loading: () => const _Frame(child: RecordSkeleton(rows: 6)),
        error: (error, _) => error is NotFoundException
            ? EmptyState(message: _s.notFound, icon: Icons.person_off_outlined)
            : ErrorView(
                exception: error is AppException ? error : const UnknownException(message: AppStrings.errorDatabaseQueryFailed),
                onRetry: () => ref.invalidate(staffProfileProvider(staffId)),
              ),
        data: (Staff staff) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffAssignmentsProvider);
            ref.invalidate(staffDetailsProvider(staffId));
            ref.invalidate(staffProfileProvider(staffId));
            await ref.read(staffProfileProvider(staffId).future);
          },
          child: _Frame(child: _ProfileBody(staff: staff, schedule: assignments.scheduleOf(staff.id))),
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(AppSizes.p16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: child,
      ),
    ),
  );
}

/// Two columns on wide windows (schedule beside contact and employment),
/// one column on phones with identity, contact, schedule, employment.
class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.staff, required this.schedule});
  final Staff staff;
  final StaffSchedule schedule;

  @override
  Widget build(BuildContext context) => RecordSurface(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final Widget identity = StaffProfileIdentity(staff: staff, schedule: schedule);
        final Widget contact = StaffContactSection(staff: staff);
        final Widget hours = StaffScheduleSection(schedule: schedule);
        final Widget employment = StaffEmploymentSection(staffId: staff.id);
        if (constraints.maxWidth < AppSizes.staffWideBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [identity, contact, hours, employment],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            identity,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: hours),
                const SizedBox(width: AppSizes.p32),
                SizedBox(
                  width: AppSizes.staffProfileSideWidth,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [contact, employment]),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
