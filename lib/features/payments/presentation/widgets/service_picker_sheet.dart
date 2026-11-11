import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../appointment/presentation/widgets/appointment_search_field.dart';
import '../../domain/service_catalog_item.dart';
import 'service_catalog_labels.dart';
import 'service_catalog_list.dart';

const _t = AppStrings.invoices;

/// Searchable picker over the active catalog, grouped like the catalog itself.
class ServicePickerSheet extends StatefulWidget {
  const ServicePickerSheet({super.key, required this.services, required this.controller});
  final List<ServiceCatalogItem> services;
  final ScrollController controller;

  static Future<ServiceCatalogItem?> show(BuildContext context, List<ServiceCatalogItem> services) =>
      AppBottomSheet.show<ServiceCatalogItem>(
        context: context,
        title: _t.chooseService,
        initialChildSize: 0.85,
        builder: (_, controller) => ServicePickerSheet(services: services, controller: controller),
      );

  @override
  State<ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<ServicePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final String query = _query.toLowerCase();
    final visible = widget.services
        .where((service) =>
            query.isEmpty ||
            service.name.toLowerCase().contains(query) ||
            service.type.label.toLowerCase().contains(query) ||
            service.type.group.label.toLowerCase().contains(query))
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.p16, 0, AppSizes.p16, AppSizes.p8),
          child: AppointmentSearchField(
            hintText: _t.searchServices,
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? ListView(
                  controller: widget.controller,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.p24),
                      child: EmptyState(
                        icon: Icons.search_off,
                        message: widget.services.isEmpty ? _t.noActiveServices : _t.noMatches,
                      ),
                    ),
                  ],
                )
              : ServiceCatalogList(
                  services: visible,
                  controller: widget.controller,
                  onOpen: (service) => Navigator.of(context).pop(service),
                ),
        ),
      ],
    );
  }
}
