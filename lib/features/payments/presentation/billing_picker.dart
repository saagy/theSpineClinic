import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_bottom_sheet.dart';
import '../../../shared/widgets/app_search_bar.dart';
import '../../../shared/widgets/patient_id_label.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../patient/presentation/widgets/patient_monogram_badge.dart';
import '../domain/billing_access.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';
import '../domain/billing_repository.dart';
import 'billing_catalog_screen.dart';
import 'billing_providers.dart';
import 'billing_ui.dart';

part 'billing_picker_sheet.dart';

Future<BillingParty?> pickBillingParty(
  BuildContext context,
  BillingLookup kind,
) => AppBottomSheet.show<BillingParty>(
  context: context,
  title: switch (kind) {
    BillingLookup.patient => billingText.pickPatient,
    BillingLookup.doctor => billingText.pickDoctor,
    BillingLookup.senior => billingText.pickConsultant,
  },
  builder: (_, scroll) => _BillingPicker<BillingParty>(
    scroll: scroll,
    search: kind == BillingLookup.patient
        ? billingText.searchPatient
        : billingText.searchDoctor,
    watch: (ref, query, offset) =>
        ref.watch(billingLookupProvider(kind, query, offset, _pageSize + 1)),
    retry: (ref, query, offset) => ref.invalidate(
      billingLookupProvider(kind, query, offset, _pageSize + 1),
    ),
    tile: (context, party) => ListTile(
      minTileHeight: AppSizes.tappableMin,
      minVerticalPadding: AppSizes.p8,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
      leading: ExcludeSemantics(
        child: PatientMonogramBadge(name: party.name, size: AppSizes.p32),
      ),
      title: Text(party.name, style: AppTextStyles.bodyBold),
      subtitle: party.fileNumber != null
          ? Wrap(
              spacing: AppSizes.p12,
              runSpacing: AppSizes.p2,
              children: [
                PatientIdLabel(party.fileNumber!),
                if (party.branch != null)
                  Text(
                    party.branch!.displayLabel,
                    style: AppTextStyles.caption,
                  ),
              ],
            )
          : party.isSenior
          ? const Text(AppStrings.seniorDoctor, style: AppTextStyles.caption)
          : null,
      onTap: () => Navigator.pop(context, party),
    ),
  ),
);

Future<BillingItem?> pickBillingService(
  BuildContext context,
  Set<String> selected,
) {
  final excluded = selected.join(',');
  return AppBottomSheet.show<BillingItem>(
    context: context,
    title: billingText.addService,
    builder: (_, scroll) => _BillingPicker<BillingItem>(
      scroll: scroll,
      search: billingText.searchServices,
      watch: (ref, query, offset) => ref.watch(
        billingCatalogProvider(
          query,
          true,
          offset: offset,
          limit: _pageSize + 1,
          excluded: excluded,
        ),
      ),
      retry: (ref, query, offset) => ref.invalidate(
        billingCatalogProvider(
          query,
          true,
          offset: offset,
          limit: _pageSize + 1,
          excluded: excluded,
        ),
      ),
      emptyCatalog: selected.isEmpty,
      emptyMessage: selected.isEmpty
          ? billingText.noActiveServices
          : billingText.allServicesSelected,
      tile: (context, item) => ListTile(
        minTileHeight: AppSizes.tappableMin,
        minVerticalPadding: AppSizes.p8,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.p12),
        leading: const Icon(Icons.medical_services_outlined),
        title: Text(item.name, style: AppTextStyles.bodyBold),
        subtitle: Text(billingAmount(item.price), style: AppTextStyles.body),
        onTap: () => Navigator.pop(context, item),
      ),
    ),
  );
}
