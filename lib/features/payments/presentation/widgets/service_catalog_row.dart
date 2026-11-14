import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/money.dart';
import '../../domain/service_catalog_item.dart';
import 'service_catalog_labels.dart';

const _t = AppStrings.invoices;

/// True when catalog rows have room for aligned columns.
bool serviceCatalogIsWide(BuildContext context, double width) =>
    width >= AppSizes.serviceCatalogWideBreakpoint &&
    MediaQuery.textScalerOf(context).scale(1) <= 1.3;

/// One service: aligned columns on wide windows, stacked text on narrow ones.
class ServiceCatalogRow extends StatelessWidget {
  const ServiceCatalogRow({super.key, required this.service, this.onTap});
  final ServiceCatalogItem service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = AppTextStyles.caption.copyWith(color: colors.onSurfaceVariant);
    final name = Text(
      service.name,
      style: AppTextStyles.bodyBold.copyWith(
        color: service.active ? colors.onSurface : colors.onSurfaceVariant,
      ),
    );
    final archived = service.active
        ? null
        : Text(
            _t.archived,
            style: AppTextStyles.captionBold.copyWith(color: colors.onSurfaceVariant),
          );
    final price = Text(
      Money.format(service.priceMinor),
      textAlign: TextAlign.end,
      style: AppTextStyles.number.copyWith(
        fontWeight: FontWeight.w600,
        color: service.active ? colors.onSurface : colors.onSurfaceVariant,
      ),
    );
    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
          child: Padding(
            padding: AppSizes.paddingCell,
            child: LayoutBuilder(
              builder: (context, box) => serviceCatalogIsWide(context, box.maxWidth)
                  ? Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: AppSizes.p8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [name, ?archived],
                          ),
                        ),
                        const SizedBox(width: AppSizes.p16),
                        SizedBox(
                          width: AppSizes.serviceSoldAsColumnWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.soldAs, style: AppTextStyles.body),
                              if (service.perSessionLabel case final each?)
                                Text(each, style: muted),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: AppSizes.serviceCreditColumnWidth,
                          child: Text(
                            service.creditsDoctors ? _t.credited : _t.notCredited,
                            style: muted,
                          ),
                        ),
                        SizedBox(width: AppSizes.servicePriceColumnWidth, child: price),
                        const SizedBox(width: AppSizes.p8),
                        _chevron(colors),
                      ],
                    )
                  : _stacked(context, name, archived, price, muted),
            ),
          ),
        ),
      ),
    );
  }

  /// Narrow rows. Enlarged text moves the price below the details so the
  /// name and package text keep the full width.
  Widget _stacked(
    BuildContext context,
    Widget name,
    Widget? archived,
    Widget price,
    TextStyle muted,
  ) {
    final colors = Theme.of(context).colorScheme;
    final bool large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        name,
        const SizedBox(height: AppSizes.p4),
        Text(service.soldAs, style: muted),
        if (service.perSessionLabel case final each?) Text(each, style: muted),
        if (!service.creditsDoctors) Text(_t.noDoctorCredit, style: muted),
        if (archived != null) ...[const SizedBox(height: AppSizes.p4), archived],
        if (large) ...[const SizedBox(height: AppSizes.p8), price],
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: details),
        if (!large) ...[const SizedBox(width: AppSizes.p12), price],
        const SizedBox(width: AppSizes.p4),
        _chevron(colors),
      ],
    );
  }

  Widget _chevron(ColorScheme colors) =>
      Icon(Icons.chevron_right, size: AppSizes.iconDefault, color: colors.onSurfaceVariant);
}

/// Column labels shown once above the list on wide windows.
class ServiceCatalogHeader extends StatelessWidget {
  const ServiceCatalogHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.captionMedium.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p8,
        AppSizes.p16 + AppSizes.p8 + AppSizes.iconDefault,
        AppSizes.p8,
      ),
      child: Row(
        children: [
          Expanded(child: Text(_t.columnService, style: style)),
          const SizedBox(width: AppSizes.p16),
          SizedBox(
            width: AppSizes.serviceSoldAsColumnWidth,
            child: Text(_t.columnSoldAs, style: style),
          ),
          SizedBox(
            width: AppSizes.serviceCreditColumnWidth,
            child: Text(_t.columnDoctors, style: style),
          ),
          SizedBox(
            width: AppSizes.servicePriceColumnWidth,
            child: Text(_t.columnPrice, style: style, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
