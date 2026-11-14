import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/record_action_menu.dart';
import '../../../shared/widgets/record_menu_select.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../appointment/presentation/widgets/appointment_search_field.dart';
import '../domain/service_catalog_item.dart';
import 'service_catalog_providers.dart';
import 'widgets/invoice_access_gate.dart';
import 'widgets/service_catalog_labels.dart';
import 'widgets/service_catalog_list.dart';

const _t = AppStrings.invoices;

/// Services and packages that can be invoiced, grouped by type.
class ServiceCatalogScreen extends ConsumerStatefulWidget {
  const ServiceCatalogScreen({super.key});

  @override
  ConsumerState<ServiceCatalogScreen> createState() => _ServiceCatalogScreenState();
}

class _ServiceCatalogScreenState extends ConsumerState<ServiceCatalogScreen> {
  String _query = '';
  ServiceShow _show = ServiceShow.active;

  @override
  Widget build(BuildContext context) => InvoiceManageGate(
    frame: _frame,
    loading: const SkeletonTileList(count: 6),
    builder: (_) => _frame(_page(ref.watch(serviceCatalogProvider))),
  );

  Widget _frame(Widget body) => Scaffold(
    appBar: AppBar(title: Text(_t.services)),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.clinicalContentMaxWidth),
          child: body,
        ),
      ),
    ),
  );

  Widget _page(AsyncValue<List<ServiceCatalogItem>> catalog) {
    final List<ServiceCatalogItem>? visible = catalog.value?.where(_matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  visible == null ? _t.servicesShort : _t.countLabel(visible.length),
                  style: AppTextStyles.bodyBold,
                ),
              ),
              const SizedBox(width: AppSizes.p12),
              FilledButton.icon(
                onPressed: () => _open(null),
                icon: const Icon(Icons.add, size: AppSizes.iconSmall),
                label: Text(_t.addService, style: AppTextStyles.bodyBold),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(AppSizes.tappableMin, AppSizes.tappableMin),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.r8)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.p16, AppSizes.p12, AppSizes.p16, AppSizes.p4),
          child: _toolbar(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(serviceCatalogProvider.future),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: catalog.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                loading: () => const SkeletonTileList(count: 6),
                error: (error, _) => _scrollable(
                  ErrorView(
                    exception: AppException.fromSupabaseException(error),
                    onRetry: () => ref.invalidate(serviceCatalogProvider),
                  ),
                ),
                data: (all) => all.isEmpty
                    ? _scrollable(
                        EmptyState(
                          icon: Icons.medical_services_outlined,
                          message: _t.noServices,
                          secondaryMessage: _t.noServicesHelp,
                          actionLabel: _t.addService,
                          onActionPressed: () => _open(null),
                        ),
                      )
                    : visible!.isEmpty
                    ? _scrollable(
                        EmptyState(
                          icon: Icons.search_off,
                          message: _query.isNotEmpty
                              ? _t.noMatches
                              : _show == ServiceShow.archived
                              ? _t.noArchived
                              : _t.noActive,
                          actionLabel: _query.isEmpty ? null : _t.clearSearch,
                          onActionPressed: _query.isEmpty
                              ? null
                              : () => setState(() => _query = ''),
                        ),
                      )
                    : ServiceCatalogList(services: visible, onOpen: (service) => _open(service.id)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Search and the status choice share a row unless enlarged text needs
  /// the search field to have the full width.
  Widget _toolbar() {
    final search = AppointmentSearchField(
      hintText: _t.searchServices,
      initialValue: _query,
      onChanged: (query) => setState(() => _query = query),
    );
    final show = RecordMenuSelect<ServiceShow>(
      label: _t.show,
      value: _show,
      options: [
        RecordMenuAction(ServiceShow.active, ServiceShow.active.label, Icons.check_circle_outline),
        RecordMenuAction(ServiceShow.archived, ServiceShow.archived.label, Icons.archive_outlined),
        RecordMenuAction(ServiceShow.all, ServiceShow.all.label, Icons.list_alt),
      ],
      onChanged: (value) => setState(() => _show = value),
    );
    if (MediaQuery.textScalerOf(context).scale(1) > 1.3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          search,
          const SizedBox(height: AppSizes.p8),
          show,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: search),
        const SizedBox(width: AppSizes.p8),
        show,
      ],
    );
  }

  bool _matches(ServiceCatalogItem service) {
    if (!_show.includes(service)) return false;
    final String query = _query.trim().toLowerCase();
    return query.isEmpty ||
        service.name.toLowerCase().contains(query) ||
        service.type.label.toLowerCase().contains(query) ||
        service.type.group.label.toLowerCase().contains(query);
  }

  /// Pull-to-refresh needs a scrollable even when there is nothing to list.
  Widget _scrollable(Widget child) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      Padding(
        padding: const EdgeInsets.only(top: AppSizes.emptyStateTopOffset),
        child: child,
      ),
    ],
  );

  void _open(String? serviceId) => context.push(AppRoutes.serviceFormLocation(serviceId));
}
