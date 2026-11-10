import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../patient/domain/clinic_location.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_money.dart';
import '../domain/billing_repository.dart';
import 'billing_editor_fields.dart';
import 'billing_picker.dart';
import 'billing_providers.dart';
import 'billing_ui.dart';

part 'billing_editor_form.dart';

class BillingEditorScreen extends ConsumerStatefulWidget {
  const BillingEditorScreen({super.key, this.invoice});
  final BillingInvoice? invoice;

  @override
  ConsumerState<BillingEditorScreen> createState() =>
      _BillingEditorScreenState();
}

class _BillingEditorScreenState extends ConsumerState<BillingEditorScreen> {
  final _form = GlobalKey<FormState>();
  final List<BillingDraftLine> _lines = [];
  BillingParty? _patient, _doctor, _consultant;
  ClinicLocation? _branch;
  late DateTime _date;
  late TextEditingController _discount;
  bool _refreshingPrices = false;

  @override
  void initState() {
    super.initState();
    final invoice = widget.invoice;
    _patient = invoice?.patient;
    _doctor = invoice?.doctor;
    _consultant = invoice?.consultant;
    _branch = invoice?.branch;
    _date = invoice?.serviceDate ?? DateUtils.dateOnly(DateTime.now());
    _discount = TextEditingController(
      text: billingDecimal(invoice?.discountBps ?? 0),
    );
    for (final line in invoice?.lines ?? const <BillingLine>[]) {
      _lines.add(
        BillingDraftLine(
          BillingItem(
            id: line.itemId,
            name: line.name,
            price: line.unitPrice,
            active: true,
            version: 0,
          ),
          line.quantity,
        ),
      );
    }
  }

  @override
  void dispose() {
    _discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(billingWriterProvider).busy || _refreshingPrices;
    final subtotal = _lines.fold(
      0,
      (sum, line) => sum + line.item.price * line.quantity,
    );
    final bps = parseBillingMinor(_discount.text);
    final total = bps == null || bps > 10000 ? null : billingNet(subtotal, bps);
    return BillingGate(
      child: PopScope(
        canPop: !busy,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              widget.invoice == null
                  ? billingText.newInvoice
                  : billingText.editDraft,
              style: AppTextStyles.headingSmall,
            ),
            actions: [
              IconButton(
                tooltip: billingText.checkSave,
                onPressed: busy ? null : _recover,
                icon: const Icon(Icons.history),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final wide = bounds.maxWidth >= AppSizes.billingTableBreakpoint;
                final fields = _fields(busy);
                final totals = BillingEditorTotals(
                  subtotal: subtotal,
                  total: total,
                );
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.p16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.clinicalContentMaxWidth,
                      ),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: fields),
                                const SizedBox(width: AppSizes.p24),
                                SizedBox(
                                  width: AppSizes.patientContextWidth,
                                  child: totals,
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                fields,
                                const SizedBox(height: AppSizes.p24),
                                totals,
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: BillingEditorFooter(
            total: total, busy: busy, onSave: _save,
          ),
        ),
      ),
    );
  }

  void _update(VoidCallback change) => setState(change);
}
