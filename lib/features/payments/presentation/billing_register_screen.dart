import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/billing_access.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_repository.dart';
import 'billing_catalog_screen.dart';
import 'billing_detail_screen.dart';
import 'billing_editor_screen.dart';
import 'billing_providers.dart';
import 'billing_register_table.dart';
import 'billing_register_toolbar.dart';
import 'billing_ui.dart';

class BillingRegisterScreen extends ConsumerStatefulWidget {
  const BillingRegisterScreen({super.key});
  @override
  ConsumerState<BillingRegisterScreen> createState() =>
      _BillingRegisterScreenState();
}

class _BillingRegisterScreenState extends ConsumerState<BillingRegisterScreen> {
  BillingFilter _filter = emptyBillingFilter;
  int _page = 0;
  static const int _pageSize = 30;

  @override
  Widget build(BuildContext context) => BillingGate(
    child: Builder(
      builder: (context) {
        final user = ref.watch(currentUserProvider).value;
        final request = billingRegisterProvider(
          _filter,
          _page * _pageSize,
          _pageSize + 1,
        );
        final data = ref.watch(request);
        final busy = ref.watch(billingWriterProvider).busy;
        return Scaffold(
          appBar: AppBar(
            title: Text(billingText.title, style: AppTextStyles.headingSmall),
            actions: [
              if (BillingAccess.canManageCatalog(user))
                IconButton(
                  tooltip: billingText.catalog,
                  icon: const Icon(Icons.inventory_2_outlined),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BillingCatalogScreen(),
                        ),
                      ),
                ),
              IconButton(
                tooltip: billingText.checkSave,
                onPressed: busy ? null : _recover,
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.patientWorkspaceMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BillingRegisterToolbar(
                        filter: _filter,
                        onChanged: (filter) => setState(() {
                          _filter = filter;
                          _page = 0;
                        }),
                        onCreate: _newInvoice,
                      ),
                      const SizedBox(height: AppSizes.p16),
                      Expanded(
                        child: data.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => billingError(
                            error,
                            () => ref.invalidate(request),
                          ),
                          data: (invoices) => Column(
                            children: [
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () => ref.refresh(request.future),
                                  child: BillingRegisterTable(
                                    invoices: invoices.take(_pageSize).toList(),
                                    onOpen: _open,
                                  ),
                                ),
                              ),
                              if (_page > 0 || invoices.length > _pageSize)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      tooltip: billingText.previous,
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: _page == 0
                                          ? null
                                          : () => setState(() => _page--),
                                    ),
                                    Text(
                                      '${billingText.page} ${_page + 1}',
                                      style: AppTextStyles.body,
                                    ),
                                    IconButton(
                                      tooltip: billingText.next,
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: invoices.length <= _pageSize
                                          ? null
                                          : () => setState(() => _page++),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Future<void> _newInvoice() async {
    final id = await Navigator.of(context, rootNavigator: true).push<String>(
      MaterialPageRoute(builder: (_) => const BillingEditorScreen()),
    );
    if (mounted && id != null) _open(id);
  }

  Future<void> _recover() async {
    final commit = await recoverBilling(
      context,
      ref,
      BillingAction.draft,
      'new',
    );
    if (mounted && commit?.invoiceId != null) _open(commit!.invoiceId!);
  }

  void _open(String id) => Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(builder: (_) => BillingDetailScreen(invoiceId: id)),
  );
}
