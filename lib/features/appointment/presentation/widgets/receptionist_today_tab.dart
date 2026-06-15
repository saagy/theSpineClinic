/// Today tab content: stats strip, search bar, and appointments grouped
/// by status (Checked In → Scheduled → Cancelled).
///
/// Rule 1 — under 200 lines.
library;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_status.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/shared/widgets/skeleton_loader.dart';

/// The "Today" tab content with stats, search, and grouped appointment list.
class ReceptionistTodayTab extends StatelessWidget {
  /// Creates a [ReceptionistTodayTab].
  const ReceptionistTodayTab({
    super.key,
    required this.state,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onStatusChanged,
  });

  final ReceptionistAppointmentsState state;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context) {
    if (state.todayLoading) {
      return const SkeletonTileList(count: 5);
    }
    if (state.todayError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${state.todayError}', style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSizes.p16),
            TextButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    final filtered = _filter(state.today);
    final checkedIn = _byStatus(filtered, AppointmentStatus.checkedIn);
    final scheduled = _byStatus(filtered, AppointmentStatus.scheduled);
    final cancelled = _byStatus(filtered, AppointmentStatus.cancelled);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => onRefresh.call(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSizes.p32),
        children: [
          _StatsStrip(state: state),
          _SearchField(onChanged: onSearchChanged),
          if (checkedIn.isNotEmpty) ...[
            _SectionHeader(title: 'Checked In', count: checkedIn.length)
                .animate()
                .fadeIn(duration: 250.ms),
            ...checkedIn.asMap().entries.map((entry) => ReceptionistAppointmentCard(
                  item: entry.value,
                  faded: true,
                  onStatusChanged: onStatusChanged,
                ).animate().fadeIn(
                      duration: 250.ms,
                      delay: ((entry.key + 1) * 30).ms,
                    )),
          ],
          if (scheduled.isNotEmpty) ...[
            _SectionHeader(title: 'Scheduled', count: scheduled.length)
                .animate()
                .fadeIn(duration: 250.ms),
            ...scheduled.asMap().entries.map((entry) => ReceptionistAppointmentCard(
                  item: entry.value,
                  onStatusChanged: onStatusChanged,
                ).animate().fadeIn(
                      duration: 250.ms,
                      delay: ((entry.key + 1) * 30).ms,
                    )),
          ],
          if (cancelled.isNotEmpty) ...[
            _SectionHeader(title: 'Cancelled', count: cancelled.length)
                .animate()
                .fadeIn(duration: 250.ms),
            ...cancelled.asMap().entries.map((entry) => ReceptionistAppointmentCard(
                  item: entry.value,
                  onStatusChanged: onStatusChanged,
                ).animate().fadeIn(
                      duration: 250.ms,
                      delay: ((entry.key + 1) * 30).ms,
                    )),
          ],
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSizes.p48),
              child: Center(child: Text('No appointments today')),
            ),
        ],
      ),
    );
  }

  List<AppointmentWithPatient> _filter(List<AppointmentWithPatient> items) {
    if (searchQuery.isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items.where((a) => a.patient.fullName.toLowerCase().contains(q)).toList();
  }

  List<AppointmentWithPatient> _byStatus(
    List<AppointmentWithPatient> items,
    AppointmentStatus status,
  ) {
    return items.where((a) => a.appointment.status == status).toList();
  }

}

/// Stats strip: Scheduled | Checked In | Cancelled.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.state});
  final ReceptionistAppointmentsState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p20, vertical: AppSizes.p12),
      child: Row(
        children: [
          _Stat(label: 'Scheduled', count: state.scheduledCount,
              color: AppColors.textSecondary),
          _divider(),
          _Stat(label: 'Checked In', count: state.checkedInCount,
              color: AppColors.success),
          _divider(),
          _Stat(label: 'Cancelled', count: state.cancelledCount,
              color: AppColors.error),
        ],
      ),
    );
  }

  Widget _divider() => const SizedBox(
        height: AppSizes.iconDefault,
        child: VerticalDivider(width: AppSizes.p24, color: AppColors.border),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(count.toString(),
              style: AppTextStyles.headingMedium.copyWith(color: color)),
          const SizedBox(height: AppSizes.p2),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p4, AppSizes.p16, AppSizes.p8),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: 'Search by patient name…',
          hintStyle: AppTextStyles.bodySecondary,
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primary, size: AppSizes.iconDefault),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p12, vertical: AppSizes.p8),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.p20, AppSizes.p16, AppSizes.p20, AppSizes.p8),
      child: Text(
        '$title · $count',
        style: AppTextStyles.captionBold
            .copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}