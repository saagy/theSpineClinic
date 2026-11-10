import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/record_action_menu.dart';
import '../../../shared/widgets/record_menu_select.dart';
import '../../patient/domain/clinic_location.dart';
import '../domain/billing_repository.dart';
import 'billing_providers.dart';
import 'billing_ui.dart';

class BillingRegisterToolbar extends ConsumerStatefulWidget {
  const BillingRegisterToolbar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.onCreate,
  });
  final BillingFilter filter;
  final ValueChanged<BillingFilter> onChanged;
  final VoidCallback onCreate;

  @override
  ConsumerState<BillingRegisterToolbar> createState() =>
      _BillingRegisterToolbarState();
}

class _BillingRegisterToolbarState
    extends ConsumerState<BillingRegisterToolbar> {
  bool _exporting = false;
  BillingFilter get _filter => widget.filter;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(billingText.subtitle, style: AppTextStyles.bodyLarge),
          ),
          RecordActionMenu<bool>(
            tooltip: billingText.exportInvoices,
            enabled: !_exporting,
            icon: _exporting ? Icons.hourglass_top : Icons.download_outlined,
            onSelected: _export,
            actions: [
              RecordMenuAction(
                false,
                billingText.exportInvoices,
                Icons.receipt_long_outlined,
              ),
              RecordMenuAction(
                true,
                billingText.exportCollections,
                Icons.payments_outlined,
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppSizes.p8),
      BillingSearchInput(
        label: billingText.searchInvoices,
        onChanged: (query) => widget.onChanged((
          query: query,
          branch: _filter.branch,
          status: _filter.status,
          from: _filter.from,
          to: _filter.to,
        )),
      ),
      const SizedBox(height: AppSizes.p8),
      Wrap(
        spacing: AppSizes.p12,
        runSpacing: AppSizes.p4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          RecordMenuSelect<ClinicLocation?>(
            label: billingText.branch,
            value: _filter.branch,
            options: [
              RecordMenuAction(
                null,
                billingText.allBranches,
                Icons.apartment_outlined,
              ),
              for (final branch in ClinicLocation.values)
                RecordMenuAction(
                  branch,
                  branch.displayLabel,
                  Icons.location_on_outlined,
                ),
            ],
            onChanged: (branch) => widget.onChanged((
              query: _filter.query,
              branch: branch,
              status: _filter.status,
              from: _filter.from,
              to: _filter.to,
            )),
          ),
          RecordMenuSelect<BillingStatus?>(
            label: AppStrings.status,
            value: _filter.status,
            options: [
              RecordMenuAction(
                null,
                billingText.allStatuses,
                Icons.filter_list,
              ),
              for (final status in BillingStatus.values)
                RecordMenuAction(
                  status,
                  billingStatusLabel(status),
                  Icons.receipt_long_outlined,
                ),
            ],
            onChanged: (status) => widget.onChanged((
              query: _filter.query,
              branch: _filter.branch,
              status: status,
              from: _filter.from,
              to: _filter.to,
            )),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text(_dateLabel(context)),
            onPressed: _pickDates,
          ),
          if (_filter.from != null)
            IconButton(
              tooltip: billingText.clearDates,
              icon: const Icon(Icons.close),
              onPressed: () => _setDates(null),
            ),
          FilledButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add),
            label: Text(billingText.newInvoice),
          ),
        ],
      ),
    ],
  );

  String _dateLabel(BuildContext context) {
    final from = _filter.from;
    final to = _filter.to;
    if (from == null || to == null) return billingText.dateRange;
    final local = MaterialLocalizations.of(context);
    return '${local.formatShortDate(from)} – ${local.formatShortDate(to)}';
  }

  Future<void> _pickDates() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _filter.from == null || _filter.to == null
          ? null
          : DateTimeRange(start: _filter.from!, end: _filter.to!),
    );
    if (mounted && picked != null) _setDates(picked);
  }

  void _setDates(DateTimeRange? range) => widget.onChanged((
    query: _filter.query,
    branch: _filter.branch,
    status: _filter.status,
    from: range?.start,
    to: range?.end,
  ));

  Future<void> _export(bool collections) async {
    setState(() => _exporting = true);
    try {
      final result = await ref
          .read(billingRepositoryProvider)
          .export(_filter, collections: collections);
      if (!mounted) return;
      final csv = result.dataOrNull;
      if (csv == null) {
        billingMessage(
          context,
          AppStrings.fromKey(result.exceptionOrNull!.userMessageKey),
        );
        return;
      }
      await FilePicker.platform.saveFile(
        fileName: collections ? 'collections.csv' : 'invoices.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(utf8.encode(csv)),
      );
    } catch (_) {
      if (mounted) billingMessage(context, AppStrings.errorUnknown);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
