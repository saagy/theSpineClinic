import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/all_appointments_providers.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/appointment_agenda_row.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_all_helpers.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';
import 'package:spine_clinic_app/shared/widgets/empty_state.dart';

/// Grouped scrollable list of appointments for [ReceptionistAllTab].
class ReceptionistAllList extends ConsumerWidget {
  const ReceptionistAllList({
    super.key,
    required this.items,
    required this.scrollController,
    required this.animatedIndices,
    required this.onStatusChanged,
  });

  final List<AppointmentWithPatient> items;
  final ScrollController scrollController;
  final Set<int> animatedIndices;
  final VoidCallback onStatusChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const EmptyState(
        message: AppStrings.noAppointmentsFound,
        icon: Icons.event_busy_rounded,
      );
    }
    final bool loadingMore = ref.watch(isLoadingMoreProvider);
    final list = buildDateGroupedList(items);
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      color: cs.primary,
      onRefresh: () async =>
          ref.read(allAppointmentsProvider.notifier).refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: AppSizes.p32),
        itemCount: list.length + (loadingMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == list.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
              child: Center(
                child: SizedBox(
                  width: AppSizes.iconDefault,
                  height: AppSizes.iconDefault,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSizes.strokeWidthThin,
                    color: cs.primary,
                  ),
                ),
              ),
            );
          }
          final item = list[i];
          if (item is AllHeaderItem) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p20,
                AppSizes.p16,
                AppSizes.p20,
                AppSizes.p8,
              ),
              child: Text(
                item.title,
                style: AppTextStyles.captionBold.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            );
          }
          final a = (item as AllApptItem).item;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedListItem(
                index: i,
                animatedIndices: animatedIndices,
                child: AppointmentAgendaRow(
                  item: a,
                  showDoctor: true,
                  onStatusChanged: onStatusChanged,
                ),
              ),
              Divider(
                height: 1,
                thickness: AppSizes.borderWidth,
                color: cs.outlineVariant.withAlpha(80),
              ),
            ],
          );
        },
      ),
    );
  }
}
