part of 'appointment_filter_main_view.dart';

extension _AppointmentFilterChrome on AppointmentFilterMainView {
  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.p20, AppSizes.p16, AppSizes.p12, AppSizes.p8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppStrings.filtersButton, style: AppTextStyles.headingMedium.copyWith(color: cs.onSurface)),
          Row(
            children: [
              TextButton(
                onPressed: onReset,
                child: Text(
                  AppStrings.resetFilters,
                  style: AppTextStyles.bodyBold.copyWith(color: cs.primary),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.p8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.captionBold.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildFooter(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant, width: AppSizes.borderWidth),
        ),
      ),
      child: FilledButton(
        onPressed: onApply,
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size.fromHeight(44.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
        ),
        child: Text(AppStrings.applyFilters, style: AppTextStyles.bodyBold),
      ),
    );
  }
}
