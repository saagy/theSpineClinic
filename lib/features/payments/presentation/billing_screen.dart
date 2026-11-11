import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/network/app_routes.dart';
import '../../../shared/widgets/profile_menu_row.dart';
import 'widgets/invoice_access_gate.dart';

const _t = AppStrings.invoices;

/// The Billing tab for payment staff. It opens the service catalog; the
/// billing reports join it here (see docs/billing-plan.md, slice 6).
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) => InvoiceManageGate(
    frame: _frame,
    loading: const SizedBox.shrink(),
    builder: (_) => _frame(
      ListView(
        padding: const EdgeInsets.all(AppSizes.p16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppSizes.profileLayoutMaxWidth),
              child: ProfileMenuRow(
                title: _t.services,
                subtitle: _t.servicesSubtitle,
                leadingIcon: Icons.medical_services_outlined,
                onTap: () => context.push(AppRoutes.serviceCatalog),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _frame(Widget body) => Scaffold(
    appBar: AppBar(title: Text(_t.billing)),
    body: body,
  );
}
