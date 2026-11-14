import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/clinic_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/app_routes.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/record_skeleton.dart';
import '../../../shared/widgets/refresh_on_return.dart';
import '../../auth/domain/staff.dart';
import '../domain/invoice_access.dart';
import '../domain/invoice_detail.dart';
import 'invoice_detail_providers.dart';
import 'widgets/invoice_access_gate.dart';
import 'widgets/invoice_detail_actions.dart';
import 'widgets/invoice_detail_body.dart';

const _t = AppStrings.invoiceDetail;

/// One invoice with its lines, money and activity. On wide windows it docks
/// to the edge as a panel over the patient page; on narrow windows, or when
/// opened directly from a link, it fills the window.
class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.patientId, required this.invoiceId});
  final String patientId;
  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool docked = context.canPop() &&
        MediaQuery.sizeOf(context).width >= AppSizes.invoicePanelBreakpoint &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    void close() => context.canPop()
        ? context.pop()
        : context.go(AppRoutes.patientDetail.replaceFirst(':id', Uri.encodeComponent(patientId)));

    Widget frame(Widget body, {InvoiceDetail? invoice, Staff? user}) {
      // Its own messenger: confirmations appear on the invoice, not also on
      // the dimmed page behind a docked panel.
      final scaffold = ScaffoldMessenger(child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: docked ? const Icon(Icons.close) : const BackButtonIcon(),
            tooltip: docked ? AppStrings.close : AppStrings.backTooltip,
            onPressed: close,
          ),
          title: Text(invoice == null ? _t.invoice : _t.title(invoice.summary.displayNumber)),
          actions: [
            if (invoice != null && user != null) InvoiceAppBarActions(invoice: invoice, user: user),
            const SizedBox(width: AppSizes.p8),
          ],
        ),
        body: body,
      ));
      if (!docked) return scaffold;
      final colors = Theme.of(context).colorScheme;
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          width: AppSizes.invoicePanelWidth,
          decoration: BoxDecoration(
            border: BorderDirectional(start: BorderSide(color: colors.outlineVariant)),
            boxShadow: [ClinicColors.of(context).elevatedShadow],
          ),
          child: scaffold,
        ),
      );
    }

    final Widget skeleton = const Padding(
      padding: EdgeInsets.all(AppSizes.p16),
      child: RecordSkeleton(rows: 4),
    );
    return InvoiceManageGate(
      allow: InvoiceAccess.canIssue,
      frame: frame,
      loading: skeleton,
      builder: (Staff user) => ref.watch(invoiceDetailProvider(invoiceId)).when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => frame(skeleton),
        error: (error, _) {
          final exception = AppException.fromSupabaseException(error);
          return frame(
            exception is NotFoundException
                ? EmptyState(
                    icon: Icons.search_off,
                    message: _t.notFound,
                    actionLabel: AppStrings.close,
                    onActionPressed: close,
                  )
                : ErrorView(
                    exception: exception,
                    onRetry: () => ref.invalidate(invoiceDetailProvider(invoiceId)),
                  ),
          );
        },
        data: (invoice) => frame(
          invoice: invoice,
          user: user,
          // Back from a refund or correction, or into the app again: other
          // staff may have taken a payment meanwhile.
          RefreshOnReturn(
            notifyOnEntry: false,
            onReturn: () {
              if (!ref.read(invoiceDetailProvider(invoiceId)).isLoading) {
                ref.invalidate(invoiceDetailProvider(invoiceId));
              }
            },
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(invoiceDetailProvider(invoiceId).future),
              child: InvoiceDetailBody(invoice: invoice, user: user),
            ),
          ),
        ),
      ),
    );
  }
}
