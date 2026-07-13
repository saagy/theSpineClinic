part of 'new_appointment_form.dart';

extension _NewAppointmentProviderSection on _NewAppointmentFormState {
  Widget _buildProviderSection(BuildContext context) {
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
            AppStrings.providerAndBilling,
            style: AppTextStyles.captionMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          if (_isFetchingDoctors) ...[
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
          AppDoctorMultiSelectField(
            key: _doctorFieldKey,
            initialValue: const [],
            enabled: _doctorFieldEnabled,
            onSavedDoctors: (_) {},
            onChanged: (_) {},
            validator: (doctors) => doctors == null || doctors.isEmpty
                ? AppStrings.atLeastOneDoctorRequired
                : null,
          ),
          const SizedBox(height: AppSizes.p16),
          if (_selectedType.affectsPackageBalance)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.usePackageBalance,
                  style: AppTextStyles.body.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p12,
                vertical: AppSizes.p8,
              ),
              decoration: BoxDecoration(
                color: ClinicColors.of(context).infoContainer,
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppSizes.r12),
                ),
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
