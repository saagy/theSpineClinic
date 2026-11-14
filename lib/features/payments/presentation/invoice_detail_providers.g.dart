// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_detail_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(invoiceDetail)
final invoiceDetailProvider = InvoiceDetailFamily._();

final class InvoiceDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<InvoiceDetail>,
          InvoiceDetail,
          FutureOr<InvoiceDetail>
        >
    with $FutureModifier<InvoiceDetail>, $FutureProvider<InvoiceDetail> {
  InvoiceDetailProvider._({
    required InvoiceDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invoiceDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invoiceDetailHash();

  @override
  String toString() {
    return r'invoiceDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InvoiceDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InvoiceDetail> create(Ref ref) {
    final argument = this.argument as String;
    return invoiceDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InvoiceDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invoiceDetailHash() => r'00d4e0fb233a06c88ee3007f32e4a9a039306988';

final class InvoiceDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InvoiceDetail>, String> {
  InvoiceDetailFamily._()
    : super(
        retry: null,
        name: r'invoiceDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InvoiceDetailProvider call(String invoiceId) =>
      InvoiceDetailProvider._(argument: invoiceId, from: this);

  @override
  String toString() => r'invoiceDetailProvider';
}

/// Runs payments, refunds, voids and corrections on an invoice. Kept alive so
/// a request finishing after its dialog or form closes still refreshes the
/// invoice, the patient's list, the session balances and the Billing reports.

@ProviderFor(InvoiceActionController)
final invoiceActionControllerProvider = InvoiceActionControllerProvider._();

/// Runs payments, refunds, voids and corrections on an invoice. Kept alive so
/// a request finishing after its dialog or form closes still refreshes the
/// invoice, the patient's list, the session balances and the Billing reports.
final class InvoiceActionControllerProvider
    extends $NotifierProvider<InvoiceActionController, InvoiceActionState> {
  /// Runs payments, refunds, voids and corrections on an invoice. Kept alive so
  /// a request finishing after its dialog or form closes still refreshes the
  /// invoice, the patient's list, the session balances and the Billing reports.
  InvoiceActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invoiceActionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invoiceActionControllerHash();

  @$internal
  @override
  InvoiceActionController create() => InvoiceActionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvoiceActionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InvoiceActionState>(value),
    );
  }
}

String _$invoiceActionControllerHash() =>
    r'8fbfc83b1f43e520909cf63ff20e59b432fb64a1';

/// Runs payments, refunds, voids and corrections on an invoice. Kept alive so
/// a request finishing after its dialog or form closes still refreshes the
/// invoice, the patient's list, the session balances and the Billing reports.

abstract class _$InvoiceActionController extends $Notifier<InvoiceActionState> {
  InvoiceActionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<InvoiceActionState, InvoiceActionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InvoiceActionState, InvoiceActionState>,
              InvoiceActionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
