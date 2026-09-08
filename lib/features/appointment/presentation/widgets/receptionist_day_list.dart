import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/receptionist_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list_helpers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// The receptionist appointment agenda list for a single day selected in the week strip.
class ReceptionistDayList extends StatelessWidget {
  const ReceptionistDayList({
    super.key,
    required this.state,
    required this.searchQuery,
    this.onStatusChanged,
    this.onRefresh,
  });

  final ReceptionistAppointmentsState state;
  final String searchQuery;
  final VoidCallback? onStatusChanged;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allItems = state.itemsForSelectedDay;
    final items = _filter(allItems);

    if (items.isEmpty) {
      final emptyWidget = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p20,
          AppSizes.p48,
          AppSizes.p20,
          AppSizes.p32,
        ),
        children: [
          EmptyState(
            icon: LucideIcons.calendar_clock,
            message: searchQuery.isNotEmpty
                ? AppStrings.noAppointmentsFound
                : AppStrings.noAppointments,
            secondaryMessage: searchQuery.isNotEmpty
                ? 'No appointments found for "$searchQuery"'
                : null,
          ),
        ],
      );

      if (onRefresh != null) {
        return RefreshIndicator(
          color: cs.primary,
          onRefresh: onRefresh!,
          child: emptyWidget,
        );
      }
      return emptyWidget;
    }

    final nowIndex = getDoctorScheduleNowIndex(
      items,
      isToday: state.isToday,
    );
    final hasNow = nowIndex >= 0;
    final totalCount = items.length + (hasNow ? 1 : 0);

    final list = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      itemCount: totalCount,
      separatorBuilder: (_, index) {
        if (hasNow && (index == nowIndex || index == nowIndex - 1)) {
          return const SizedBox.shrink();
        }
        return Divider(
          height: AppSizes.borderWidth,
          thickness: AppSizes.borderWidth,
          indent: AppSizes.p16,
          endIndent: AppSizes.p16,
          color: cs.outlineVariant.withAlpha(80),
        );
      },
      itemBuilder: (context, index) {
        if (hasNow && index == nowIndex) {
          return const ScheduleNowIndicator();
        }

        final itemIndex = hasNow && index > nowIndex ? index - 1 : index;
        final item = items[itemIndex];
        return AppointmentAgendaRow(
          key: ValueKey(item.appointment.id),
          item: item,
          showDoctor: true,
          onStatusChanged: onStatusChanged,
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        color: cs.primary,
        onRefresh: onRefresh!,
        child: list,
      );
    }
    return list;
  }

  List<AppointmentWithPatient> _filter(List<AppointmentWithPatient> items) {
    if (searchQuery.isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items
        .where((a) => a.patient.fullName.toLowerCase().contains(q))
        .toList();
  }
}
