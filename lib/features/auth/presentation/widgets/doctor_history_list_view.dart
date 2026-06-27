import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/domain/appointment_repository.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/receptionist_appointment_card.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/shared/widgets/animated_list_item.dart';

class DoctorHistoryListView extends StatefulWidget {
  const DoctorHistoryListView({
    super.key,
    required this.items,
    required this.scrollController,
    required this.onRefresh,
    this.onStatusChanged,
  });

  final List<DoctorScheduleItem> items;
  final ScrollController scrollController;
  final RefreshCallback onRefresh;
  final VoidCallback? onStatusChanged;

  @override
  State<DoctorHistoryListView> createState() => _DoctorHistoryListViewState();
}

class _DoctorHistoryListViewState extends State<DoctorHistoryListView> {
  final Set<int> _animatedIndices = <int>{};

  @override
  void didUpdateWidget(DoctorHistoryListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _animatedIndices.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_ListItem> displayItems = _buildListItems(widget.items);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: widget.scrollController,
        padding: const EdgeInsets.only(
          bottom: AppSizes.p32,
        ),
        itemCount: displayItems.length,
        itemBuilder: (context, int index) {
          final _ListItem listItem = displayItems[index];
          if (listItem is _HeaderItem) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.p8, AppSizes.p20, AppSizes.p8, AppSizes.p8,
              ),
              child: Text(
                listItem.title,
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          final DoctorScheduleItem item = (listItem as _HistoryItem).item;
          return AnimatedListItem(
            index: index,
            animatedIndices: _animatedIndices,
            child: ReceptionistAppointmentCard(
              key: ValueKey(item.appointment.id),
              item: AppointmentWithPatient(
                appointment: item.appointment,
                patient: item.patient,
              ),
              showMenu: true,
              onStatusChanged: widget.onStatusChanged,
            ),
          );
        },
      ),
    );
  }

  List<_ListItem> _buildListItems(List<DoctorScheduleItem> items) {
    final List<_ListItem> listItems = [];
    String? lastHeader;

    for (final item in items) {
      final date = item.appointment.scheduledAt.toLocal();
      final header = _getGroupHeader(date);
      if (header != lastHeader) {
        listItems.add(_HeaderItem(header));
        lastHeader = header;
      }
      listItems.add(_HistoryItem(item));
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
    return DateFormat('EEEE, MMM d').format(localDate);
  }
}

sealed class _ListItem {}

class _HeaderItem extends _ListItem {
  _HeaderItem(this.title);
  final String title;
}

class _HistoryItem extends _ListItem {
  _HistoryItem(this.item);
  final DoctorScheduleItem item;
}
