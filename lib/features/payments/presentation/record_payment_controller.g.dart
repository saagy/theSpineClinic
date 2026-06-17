// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record_payment_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the [PaymentRepository] instance.

@ProviderFor(paymentRepository)
final paymentRepositoryProvider = PaymentRepositoryProvider._();

/// Provider for the [PaymentRepository] instance.

final class PaymentRepositoryProvider
    extends
        $FunctionalProvider<
          PaymentRepository,
          PaymentRepository,
          PaymentRepository
        >
    with $Provider<PaymentRepository> {
  /// Provider for the [PaymentRepository] instance.
  PaymentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentRepositoryHash();

  @$internal
  @override
  $ProviderElement<PaymentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PaymentRepository create(Ref ref) {
    return paymentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentRepository>(value),
    );
  }
}

String _$paymentRepositoryHash() => r'6a0f5ada6b16c29802c1f4b384899e78c5e01498';

/// Provider fetching available clinic packages.

@ProviderFor(clinicPackages)
final clinicPackagesProvider = ClinicPackagesProvider._();

/// Provider fetching available clinic packages.

final class ClinicPackagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ClinicPackage>>,
          List<ClinicPackage>,
          FutureOr<List<ClinicPackage>>
        >
    with
        $FutureModifier<List<ClinicPackage>>,
        $FutureProvider<List<ClinicPackage>> {
  /// Provider fetching available clinic packages.
  ClinicPackagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clinicPackagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clinicPackagesHash();

  @$internal
  @override
  $FutureProviderElement<List<ClinicPackage>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ClinicPackage>> create(Ref ref) {
    return clinicPackages(ref);
  }
}

String _$clinicPackagesHash() => r'5699c652cc63775975570c5cca744d2babe56c7c';

/// Provider fetching payment records for a patient.

@ProviderFor(patientPayments)
final patientPaymentsProvider = PatientPaymentsFamily._();

/// Provider fetching payment records for a patient.

final class PatientPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PaymentRecord>>,
          List<PaymentRecord>,
          FutureOr<List<PaymentRecord>>
        >
    with
        $FutureModifier<List<PaymentRecord>>,
        $FutureProvider<List<PaymentRecord>> {
  /// Provider fetching payment records for a patient.
  PatientPaymentsProvider._({
    required PatientPaymentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'patientPaymentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$patientPaymentsHash();

  @override
  String toString() {
    return r'patientPaymentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PaymentRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PaymentRecord>> create(Ref ref) {
    final argument = this.argument as String;
    return patientPayments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PatientPaymentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$patientPaymentsHash() => r'd1f31d0b58d62ef111c98d2b9bd9b25a739f7d5d';

/// Provider fetching payment records for a patient.

final class PatientPaymentsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PaymentRecord>>, String> {
  PatientPaymentsFamily._()
    : super(
        retry: null,
        name: r'patientPaymentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider fetching payment records for a patient.

  PatientPaymentsProvider call(String patientId) =>
      PatientPaymentsProvider._(argument: patientId, from: this);

  @override
  String toString() => r'patientPaymentsProvider';
}

/// Controller managing form submission state for the record payment screen.

@ProviderFor(RecordPaymentController)
final recordPaymentControllerProvider = RecordPaymentControllerProvider._();

/// Controller managing form submission state for the record payment screen.
final class RecordPaymentControllerProvider
    extends $AsyncNotifierProvider<RecordPaymentController, void> {
  /// Controller managing form submission state for the record payment screen.
  RecordPaymentControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recordPaymentControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recordPaymentControllerHash();

  @$internal
  @override
  RecordPaymentController create() => RecordPaymentController();
}

String _$recordPaymentControllerHash() =>
    r'533ab58d4f4e0c85bc73f080138e9b55016b693a';

/// Controller managing form submission state for the record payment screen.

abstract class _$RecordPaymentController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
