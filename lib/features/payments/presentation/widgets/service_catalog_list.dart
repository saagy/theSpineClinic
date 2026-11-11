import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/service_catalog_item.dart';
import 'service_catalog_labels.dart';
import 'service_catalog_row.dart';

/// Services grouped by type, each group in one bordered surface.
class ServiceCatalogList extends StatelessWidget {
  const ServiceCatalogList({
    super.key,
    required this.services,
    required this.onOpen,
    this.controller,
  });
  final List<ServiceCatalogItem> services;
  final ValueChanged<ServiceCatalogItem> onOpen;

  /// The surrounding sheet's controller when shown as a picker.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final groups = groupServices(services);
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final wide = serviceCatalogIsWide(context, box.maxWidth - AppSizes.p32);
        return ListView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSizes.p16, AppSizes.p4, AppSizes.p16, AppSizes.p32,
          ),
          children: [
            if (wide) const ServiceCatalogHeader(),
            for (final (index, (group, items)) in groups.indexed) ...[
              Padding(
                padding: EdgeInsets.only(
                  top: index == 0 && wide ? AppSizes.p4 : AppSizes.p20,
                  bottom: AppSizes.p8,
                ),
                child: Semantics(
                  header: true,
                  child: Text(
                    group.label,
                    style: AppTextStyles.captionBold.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Material(
                color: colors.surface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: colors.outlineVariant),
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: Column(
                  children: [
                    for (final (row, service) in items.indexed) ...[
                      if (row > 0)
                        Divider(
                          height: AppSizes.borderWidth,
                          thickness: AppSizes.borderWidth,
                          color: colors.outlineVariant,
                        ),
                      ServiceCatalogRow(
                        service: service,
                        onTap: () => onOpen(service),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
