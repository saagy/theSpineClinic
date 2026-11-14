import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/core/errors/app_exception.dart';
import 'package:spine_clinic_app/core/utils/formatters.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/features/staff/domain/staff_details.dart';
import 'package:spine_clinic_app/features/staff/presentation/staff_details_providers.dart';
import 'package:spine_clinic_app/shared/widgets/error_view.dart';
import 'package:spine_clinic_app/shared/widgets/record_section.dart';
import 'package:spine_clinic_app/shared/widgets/record_skeleton.dart';

const _s = AppStrings.staffSchedule;
const _d = AppStrings.staffDetails;

/// Whole years and months from [from] to [to].
({int years, int months}) elapsedYearsMonths(DateTime from, DateTime to) {
  int months = (to.year - from.year) * 12 + to.month - from.month;
  if (to.day < from.day) months--;
  if (months < 0) months = 0;
  return (years: months ~/ 12, months: months % 12);
}

/// National ID (masked until shown), date of birth with age, hire date with
/// time at the clinic, and who last changed them.
class StaffEmploymentSection extends ConsumerStatefulWidget {
  const StaffEmploymentSection({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<StaffEmploymentSection> createState() => _StaffEmploymentSectionState();
}

class _StaffEmploymentSectionState extends ConsumerState<StaffEmploymentSection> {
  bool _showId = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final AsyncValue<StaffDetails> details = ref.watch(staffDetailsProvider(widget.staffId));
    return RecordSection(
      title: _d.section,
      child: details.when(
        loading: () => const RecordSkeleton(rows: 3),
        error: (error, _) => ErrorView(
          exception: error is AppException ? error : UnknownException(message: _d.loadFailed),
          onRetry: () => ref.invalidate(staffDetailsProvider(widget.staffId)),
        ),
        data: (StaffDetails d) {
          if (d.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p12),
              child: Text(
                ref.watch(currentUserProvider).value?.isHeadReceptionist ?? false
                    ? _s.employmentHidden
                    : _s.noEmploymentDetails,
                style: AppTextStyles.bodySecondary.copyWith(color: colors.onSurfaceVariant),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.nationalId != null) _nationalId(context, d.nationalId!),
              if (d.birthDate != null)
                RecordFact(
                  label: _d.birthDate,
                  value: _s.withDetail(
                    Formatters.formatDateMedium(d.birthDate!),
                    _s.age(elapsedYearsMonths(d.birthDate!, DateTime.now()).years),
                  ),
                ),
              if (d.hireDate != null) _hire(d.hireDate!),
              if (d.updatedAt != null) _updated(context, d),
            ],
          );
        },
      ),
    );
  }

  Widget _hire(DateTime hired) {
    final DateTime now = DateTime.now();
    final String date = Formatters.formatDateMedium(hired);
    if (hired.isAfter(now)) return RecordFact(label: _d.hireDate, value: date);
    final span = elapsedYearsMonths(hired, now);
    return RecordFact(label: _d.hireDate, value: _s.withDetail(date, _s.tenure(span.years, span.months)));
  }

  Widget _nationalId(BuildContext context, String id) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: RecordFact(
          label: _d.nationalId,
          value: _showId ? id : _s.maskedId(id.substring(id.length - 4)),
        ),
      ),
      TextButton(
        onPressed: () => setState(() => _showId = !_showId),
        style: TextButton.styleFrom(minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin)),
        child: Text(
          _showId ? _s.hide : _s.show,
          semanticsLabel: _showId ? _s.hideNationalId : _s.showNationalId,
        ),
      ),
    ],
  );

  Widget _updated(BuildContext context, StaffDetails d) {
    final String when = Formatters.formatDateMedium(d.updatedAt!);
    final String? editor = d.updatedById == null
        ? null
        : ref.watch(staffProfileProvider(d.updatedById!)).value?.fullName;
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.p8),
      child: Text(
        editor == null ? _s.updatedOn(when) : _s.updatedBy(editor, when),
        style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
