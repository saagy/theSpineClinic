import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';
import '../domain/billing_repository.dart';
import 'billing_providers.dart';
import 'billing_ui.dart';

part 'billing_catalog_editor.dart';

class BillingCatalogScreen extends ConsumerStatefulWidget {
  const BillingCatalogScreen({super.key});
  @override
  ConsumerState<BillingCatalogScreen> createState() =>
      _BillingCatalogScreenState();
}

class _BillingCatalogScreenState extends ConsumerState<BillingCatalogScreen> {
  String _query = '';
  bool _archived = true;

  @override
  Widget build(BuildContext context) => BillingGate(
    catalog: true,
    child: Builder(
      builder: (context) {
        final request = billingCatalogProvider(_query, !_archived);
        final data = ref.watch(request);
        final busy = ref.watch(billingWriterProvider).busy;
        return Scaffold(
          appBar: AppBar(
            title: Text(billingText.catalog, style: AppTextStyles.headingSmall),
            actions: [
              IconButton(
                tooltip: billingText.checkSave,
                icon: const Icon(Icons.history),
                onPressed: busy
                    ? null
                    : () => recoverBilling(
                        context,
                        ref,
                        BillingAction.item,
                        'new',
                      ),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.clinicalContentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        billingText.catalogSubtitle,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: AppSizes.p12),
                      BillingSearchInput(
                        label: billingText.searchServices,
                        onChanged: (query) => setState(() => _query = query),
                      ),
                      const SizedBox(height: AppSizes.p12),
                      Wrap(
                        spacing: AppSizes.p12,
                        runSpacing: AppSizes.p8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: busy ? null : () => _edit(null),
                            icon: const Icon(Icons.add),
                            label: Text(billingText.newService),
                          ),
                          FilterChip(
                            label: Text(
                              billingText.includeArchived,
                              style: AppTextStyles.body,
                            ),
                            selected: _archived,
                            onSelected: (value) =>
                                setState(() => _archived = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.p12),
                      Expanded(
                        child: data.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => billingError(
                            error,
                            () => ref.invalidate(request),
                          ),
                          data: (items) => items.isEmpty
                              ? BillingEmpty(billingText.noServices)
                              : RefreshIndicator(
                                  onRefresh: () => ref.refresh(request.future),
                                  child: ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    separatorBuilder: (_, _) => const Divider(
                                      height: AppSizes.borderWidth,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return ListTile(
                                        title: Text(
                                          item.name,
                                          style: AppTextStyles.bodyBold,
                                        ),
                                        subtitle: Text(
                                          '${billingAmount(item.price)}${item.active ? '' : ' · ${billingText.inactive}'}',
                                          style: AppTextStyles.body,
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                        ),
                                        onTap: busy ? null : () => _edit(item),
                                      );
                                    },
                                  ),
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

  Future<void> _edit(BillingItem? item) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CatalogEditDialog(item: item),
  );
}
