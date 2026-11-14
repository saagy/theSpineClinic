// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(patientInvoices)
final patientInvoicesProvider = PatientInvoicesFamily._();

final class PatientInvoicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InvoiceSummary>>,
          List<InvoiceSummary>,
          FutureOr<List<InvoiceSummary>>
        >
    with
        $FutureModifier<List<InvoiceSummary>>,
        $FutureProvider<List<InvoiceSummary>> {
  PatientInvoicesProvider._({
    required PatientInvoicesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientInvoicesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientInvoicesHash();

  @override
  String toString() {
    return r'patientInvoicesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<InvoiceSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InvoiceSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return patientInvoices(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientInvoicesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientInvoicesHash() => r'2e021db86f1e8e1780353aeb16eea114223cb27b';

final class PatientInvoicesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<InvoiceSummary>>, String> {
  PatientInvoicesFamily._()
    : super(
        retry: null,
        name: r'patientInvoicesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PatientInvoicesProvider call(String patientId) =>
      PatientInvoicesProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientInvoicesProvider';
}

/// Issues new invoices. Kept alive so a request finishing after the form
/// closes still refreshes the patient's invoices, session balances and the
/// Billing reports.

@ProviderFor(InvoiceCreateController)
final invoiceCreateControllerProvider = InvoiceCreateControllerProvider._();

/// Issues new invoices. Kept alive so a request finishing after the form
/// closes still refreshes the patient's invoices, session balances and the
/// Billing reports.
final class InvoiceCreateControllerProvider
    extends $NotifierProvider<InvoiceCreateController, InvoiceCreateState> {
  /// Issues new invoices. Kept alive so a request finishing after the form
  /// closes still refreshes the patient's invoices, session balances and the
  /// Billing reports.
  InvoiceCreateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceCreateControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceCreateControllerHash();

  @$internal
  @override
  InvoiceCreateController create() => InvoiceCreateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvoiceCreateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvoiceCreateState>(value),
    );
  }
}

String _$invoiceCreateControllerHash() =>
    r'b46f3c55616833e39501040f2814ba4e5f4ec75b';

/// Issues new invoices. Kept alive so a request finishing after the form
/// closes still refreshes the patient's invoices, session balances and the
/// Billing reports.

abstract class _$InvoiceCreateController extends $Notifier<InvoiceCreateState> {
  InvoiceCreateState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<InvoiceCreateState, InvoiceCreateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InvoiceCreateState, InvoiceCreateState>,
              InvoiceCreateState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
