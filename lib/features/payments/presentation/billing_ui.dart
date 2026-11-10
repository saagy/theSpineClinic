import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/result.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/billing_access.dart';
import '../domain/billing_invoice.dart';
import '../domain/billing_repository.dart';
import 'billing_providers.dart';

const billingText = AppStrings.billing;

class BillingGate extends ConsumerWidget {
  const BillingGate({super.key, required this.child, this.catalog = false});
  final Widget child;
  final bool catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: billingError(error, () => ref.invalidate(currentUserProvider)),
      ),
      data: (staff) =>
          (catalog
              ? BillingAccess.canManageCatalog(staff)
              : BillingAccess.canTransact(staff))
          ? child
          : Scaffold(
              appBar: AppBar(title: Text(billingText.title)),
              body: BillingEmpty(billingText.unavailable),
            ),
    );
  }
}

Widget billingError(Object error, VoidCallback retry) => ErrorView(
  exception: error is AppException
      ? error
      : const UnknownException(message: 'Billing query failed'),
  onRetry: retry,
);

class BillingEmpty extends StatelessWidget {
  const BillingEmpty(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.p24),
      child: Text(
        message,
        style: AppTextStyles.body,
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class BillingSearchInput extends StatefulWidget {
  const BillingSearchInput({
    super.key,
    required this.label,
    required this.onChanged,
    this.autofocus = false,
  });
  final String label;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  @override
  State<BillingSearchInput> createState() => _BillingSearchInputState();
}

class _BillingSearchInputState extends State<BillingSearchInput> {
  Timer? _debounce;
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    autofocus: widget.autofocus,
    style: AppTextStyles.body,
    decoration: InputDecoration(
      labelText: widget.label,
      prefixIcon: const Icon(Icons.search),
    ),
    onChanged: (value) {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => widget.onChanged(value),
      );
    },
  );
}

void billingMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message, style: AppTextStyles.body)));
}

Future<BillingCommit?> submitBilling(
  BuildContext context,
  WidgetRef ref,
  BillingCommand command, {
  ValueChanged<String>? onMessage,
}) async {
  final writer = ref.read(billingWriterProvider.notifier);
  final result = await writer.submit(command);
  if (!context.mounted) return null;
  final error = result.exceptionOrNull;
  if (error?.code == 'mutation/unconfirmed') {
    _message(context, billingText.checking, onMessage);
    return recoverBilling(
      context,
      ref,
      command.action,
      command.subject,
      quiet: true,
      onMessage: onMessage,
    );
  }
  if (error != null) {
    _message(context, AppStrings.fromKey(error.userMessageKey), onMessage);
  }
  return result.dataOrNull;
}

Future<BillingCommit?> recoverBilling(
  BuildContext context,
  WidgetRef ref,
  BillingAction action,
  String subject, {
  bool quiet = false,
  ValueChanged<String>? onMessage,
}) async {
  final Result<BillingCommit?> result = await ref
      .read(billingWriterProvider.notifier)
      .recover(action, subject);
  if (!context.mounted) return null;
  final error = result.exceptionOrNull;
  if (error != null) {
    _message(
      context,
      error.code == 'mutation/unconfirmed'
          ? '${billingText.checking}. ${billingText.recoveryHelp}'
          : AppStrings.fromKey(error.userMessageKey),
      onMessage,
    );
  } else if (!quiet) {
    _message(
      context,
      result.dataOrNull == null ? billingText.noPending : billingText.saved,
      onMessage,
    );
  }
  return result.dataOrNull;
}

void _message(
  BuildContext context,
  String message,
  ValueChanged<String>? callback,
) {
  if (callback == null) {
    billingMessage(context, message);
  } else {
    callback(message);
  }
}

String billingDocumentLabel(BillingDocumentKind kind) => switch (kind) {
  BillingDocumentKind.invoice => billingText.invoice,
  BillingDocumentKind.receipt => billingText.receipt,
  BillingDocumentKind.credit => billingText.returnDocument,
  BillingDocumentKind.refund => billingText.refundDocument,
};

String billingMethodLabel(BillingMethod method) =>
    method == BillingMethod.cash ? billingText.cash : billingText.visa;

String billingStatusLabel(BillingStatus status) => switch (status) {
  BillingStatus.draft => billingText.draft,
  BillingStatus.outstanding => billingText.outstanding,
  BillingStatus.settled => billingText.settled,
};

String billingPartyLabel(BillingParty party) => party.fileNumber == null
    ? party.name
    : '${party.name} · ${AppStrings.patientIdLabel(party.fileNumber!)}';

String billingPaymentState(BillingInvoice invoice) {
  if (invoice.isDraft) return billingText.draft;
  if (invoice.outstanding == 0) return billingText.settled;
  return invoice.collected > 0
      ? billingText.partiallyPaid
      : billingText.awaiting;
}
