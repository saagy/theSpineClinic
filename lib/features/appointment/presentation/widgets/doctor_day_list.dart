import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/appointment/presentation/doctor_schedule_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_day_list_helpers.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// The doctor's daily appointment agenda list.
class DoctorDayList extends StatelessWidget {
  const DoctorDayList({
    super.key,
    required this.state,
    this.onStatusChanged,
    this.onRefresh,
  });

  final DoctorScheduleState state;
  final VoidCallback? onStatusChanged;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = state.itemsForSelectedDay;

    if (items.isEmpty) {
      final emptyWidget = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.p20,
          AppSizes.p48,
          AppSizes.p20,
          AppSizes.p32,
        ),
        children: const [
          EmptyState(
            icon: LucideIcons.calendar_check,
            message: AppStrings.noAppointmentsFound,
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
      itemBuilder: (_, index) {
        if (hasNow && index == nowIndex) {
          return const ScheduleNowIndicator();
        }

        final cardIndex = hasNow && index > nowIndex ? index - 1 : index;
        final item = items[cardIndex];
        return AppointmentAgendaRow(
          key: ValueKey(item.appointment.id),
          item: item,
          showDoctor: false,
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
}
