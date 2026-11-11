import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/form_page_skeleton.dart';
import 'service_catalog_providers.dart';
import 'widgets/invoice_access_gate.dart';
import 'widgets/service_form_body.dart';

const _t = AppStrings.invoices;

/// Route entry for adding ([serviceId] null) or editing a catalog service.
class ServiceFormScreen extends ConsumerWidget {
  const ServiceFormScreen({super.key, this.serviceId});
  final String? serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => InvoiceManageGate(
    frame: _frame,
    loading: const FormPageSkeleton(),
    builder: (_) {
      if (serviceId == null) return const ServiceFormBody();
      return ref.watch(serviceCatalogProvider).when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => _frame(const FormPageSkeleton()),
        error: (error, _) => _frame(
          ErrorView(
            exception: AppException.fromSupabaseException(error),
            onRetry: () => ref.invalidate(serviceCatalogProvider),
          ),
        ),
        data: (services) {
          final service = services.where((item) => item.id == serviceId).firstOrNull;
          return service == null
              ? _frame(
                  EmptyState(
                    icon: Icons.search_off,
                    message: _t.serviceNotFound,
                    actionLabel: _t.services,
                    onActionPressed: () => context.go(AppRoutes.serviceCatalog),
                  ),
                )
              : ServiceFormBody(key: ValueKey(service.id), service: service);
        },
      );
    },
  );

  Widget _frame(Widget body) => Scaffold(
    appBar: AppBar(title: Text(serviceId == null ? _t.addService : _t.editService)),
    body: body,
  );
}
