part of 'new_appointment_form.dart';

extension _NewAppointmentProviderSection on _NewAppointmentFormState {
  Widget _buildProviderSection(BuildContext context) {
    final Patient? patient = _resolvePatient();
    final ClinicLocation? branch = _bookingBranch(patient);
    final TimeOfDay? time = _selectedTime;
    return FormSection(
      title: AppStrings.providerAndBilling,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingBranchField(
            value: branch,
            registeredAt: patient?.clinic,
            onChanged: (next) => _mutate(() => _branch = next),
          ),
          const SizedBox(height: AppSizes.p16),
          if (_isFetchingDoctors && _selectedType.needsDoctor) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p8),
              child: Row(
                children: [
                  SizedBox(
                    width: AppSizes.iconDefault,
                    height: AppSizes.iconDefault,
                    child: CircularProgressIndicator(
                      strokeWidth: AppSizes.strokeWidthThin,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.p12),
                  Text(
                    AppStrings.loadingAssignedDoctors,
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.p8),
          ],
          // Kept in the tree while hidden so a doctor choice survives
          // switching to traction and back.
          Visibility(
            visible: _selectedType.needsDoctor,
            maintainState: true,
            child: DoctorSelectField(
              key: _doctorFieldKey,
              initialValue: const [],
              enabled: _doctorFieldEnabled,
              branch: branch,
              collapseOtherBranches: true,
              onSavedDoctors: (_) {},
              onChanged: (doctors) => _mutate(() => _doctors = doctors),
              validator: (doctors) =>
                  _selectedType.needsDoctor && (doctors == null || doctors.isEmpty)
                  ? AppStrings.atLeastOneDoctorRequired
                  : null,
            ),
          ),
          if (_selectedType.needsDoctor && branch != null && time != null) ...[
            const SizedBox(height: AppSizes.p12),
            BookingScheduleWarnings(
              doctors: _doctors,
              branch: branch,
              starts: [
                for (final day in _computedSlots)
                  DateTime(day.year, day.month, day.day, time.hour, time.minute),
              ],
            ),
          ],
          if (!_selectedType.needsDoctor)
            Text(
              AppStrings.tractionNoDoctor,
              style: AppTextStyles.body.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (!_selectedType.affectsPackageBalance) ...[
            const SizedBox(height: AppSizes.p8),
            const Text(
              AppStrings.assessmentDoctorReminder,
              style: AppTextStyles.caption,
            ),
          ],
          const SizedBox(height: AppSizes.p16),
          if (_selectedType.affectsPackageBalance)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppStrings.usePackageBalance,
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: _usePackage,
                  onChanged: (value) => _mutate(() => _usePackage = value),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p12, vertical: AppSizes.p8),
              decoration: BoxDecoration(
                color: ClinicColors.of(context).infoContainer,
                borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: AppSizes.iconSmall,
                    color: ClinicColors.of(context).info,
                  ),
                  const SizedBox(width: AppSizes.p8),
                  Expanded(
                    child: Text(
                      AppStrings.paidSeparately,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
