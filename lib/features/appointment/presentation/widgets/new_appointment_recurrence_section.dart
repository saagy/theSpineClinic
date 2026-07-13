part of 'new_appointment_form.dart';

extension _NewAppointmentRecurrenceSection on _NewAppointmentFormState {
  Widget _buildRecurrenceSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r16)),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: AppSizes.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.recurrencePattern,
            style: AppTextStyles.captionMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          if (_selectedDate != null && _selectedWeekdays.isNotEmpty) ...[
            RecurrenceGuide(
              startDate: _selectedDate!,
              selectedWeekdays: _selectedWeekdays,
              totalSessions: int.tryParse(_sessionsController.text) ?? 0,
              slots: _computedSlots,
            ),
            const SizedBox(height: AppSizes.p12),
          ],
          RecurringPatternPicker(
            selectedWeekdays: _selectedWeekdays,
            onWeekdaysChanged: (days) =>
                _mutate(() => _selectedWeekdays = days),
            sessionsController: _sessionsController,
            daysErrorText: _daysErrorText,
            sessionsValidator: (value) {
              if (!_isRecurring) return null;
              if (value == null || value.trim().isEmpty) {
                return AppStrings.sessionsRequired;
              }
              final int? sessions = int.tryParse(value);
              if (sessions == null || sessions < 1 || sessions > 24) {
                return AppStrings.sessionsRangeValidator;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
