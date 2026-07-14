/// Bottom-sheet wrapper that lets the receptionist pick the day on which the
/// absent doctor will be away. Inserted between the "Pick the absent doctor"
/// sheet and the appointment fetch + replacement modal.
///
/// Returns the chosen date (date-only, midnight) on Continue, or `null` if
/// the sheet is dismissed.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/features/appointment/presentation/widgets/day_chip_row.dart';
import 'package:spine_clinic_app/shared/widgets/app_bottom_sheet.dart';
import 'package:spine_clinic_app/shared/widgets/app_button.dart';

/// Opens the day picker sheet. Returns the chosen [DateTime] (midnight), or
/// `null` if the receptionist dismisses without choosing.
class ReplacementDayPickerSheet {
  const ReplacementDayPickerSheet._();

  static Future<DateTime?> show({
    required BuildContext context,
    required String absentDoctorName,
    required DateTime defaultDate,
  }) {
    return AppBottomSheet.show<DateTime>(
      context: context,
      title: AppStrings.replacementDayPickerTitle,
      initialChildSize: 0.45,
      minChildSize: 0.35,
      builder: (sheetContext, _) {
        return _ReplacementDayPickerBody(
          absentDoctorName: absentDoctorName,
          defaultDate: defaultDate,
          onSubmit: (date) => Navigator.of(sheetContext).pop(date),
        );
      },
    );
  }
}

class _ReplacementDayPickerBody extends StatefulWidget {
  const _ReplacementDayPickerBody({
    required this.absentDoctorName,
    required this.defaultDate,
    required this.onSubmit,
  });

  final String absentDoctorName;
  final DateTime defaultDate;
  final ValueChanged<DateTime> onSubmit;

  @override
  State<_ReplacementDayPickerBody> createState() =>
      _ReplacementDayPickerBodyState();
}

class _ReplacementDayPickerBodyState
    extends State<_ReplacementDayPickerBody> {
  late DateTime _selected = _clamp(widget.defaultDate);

  static DateTime _clamp(DateTime date) {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime normalized = DateUtils.dateOnly(date);
    return normalized.isBefore(today) ? today : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p24,
        AppSizes.p8,
        AppSizes.p24,
        AppSizes.p16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.replacementDayPickerSubtitle(widget.absentDoctorName),
            style: AppTextStyles.bodySecondary.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppSizes.p16),
          DayChipRow(
            initialDate: _selected,
            onChanged: (date) => setState(() => _selected = date),
          ),
          const SizedBox(height: AppSizes.p24),
          AppButton(
            labelText: AppStrings.dayPickerContinue,
            onPressed: () => widget.onSubmit(_selected),
          ),
        ],
      ),
    );
  }
}
