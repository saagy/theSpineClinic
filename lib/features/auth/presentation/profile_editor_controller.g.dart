// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_editor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every active role may edit its own account; drafts never supply privileges.

@ProviderFor(ProfileEditorController)
final profileEditorControllerProvider = ProfileEditorControllerFamily._();

/// Every active role may edit its own account; drafts never supply privileges.
final class ProfileEditorControllerProvider
    extends $NotifierProvider<ProfileEditorController, ProfileEditorState> {
  /// Every active role may edit its own account; drafts never supply privileges.
  ProfileEditorControllerProvider._({
    required ProfileEditorControllerFamily super.from,
    required (String, {bool passwordOnly}) super.argument,
  }) : super(
         retry: null,
         name: r'profileEditorControllerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$profileEditorControllerHash();

  @override
  String toString() {
    return r'profileEditorControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ProfileEditorController create() => ProfileEditorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileEditorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileEditorState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileEditorControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$profileEditorControllerHash() =>
    r'3f5d0d9d00468ea53937c9c035e857c18c2f5b87';

/// Every active role may edit its own account; drafts never supply privileges.

final class ProfileEditorControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ProfileEditorController,
          ProfileEditorState,
          ProfileEditorState,
          ProfileEditorState,
          (String, {bool passwordOnly})
        > {
  ProfileEditorControllerFamily._()
    : super(
        retry: null,
        name: r'profileEditorControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Every active role may edit its own account; drafts never supply privileges.

  ProfileEditorControllerProvider call(
    String staffId, {
    bool passwordOnly = false,
  }) => ProfileEditorControllerProvider._(
    argument: (staffId, passwordOnly: passwordOnly),
    from: this,
  );

  @override
  String toString() => r'profileEditorControllerProvider';
}

/// Every active role may edit its own account; drafts never supply privileges.

abstract class _$ProfileEditorController extends $Notifier<ProfileEditorState> {
  late final _$args = ref.$arg as (String, {bool passwordOnly});
  String get staffId => _$args.$1;
  bool get passwordOnly => _$args.passwordOnly;

  ProfileEditorState build(String staffId, {bool passwordOnly = false});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProfileEditorState, ProfileEditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProfileEditorState, ProfileEditorState>,
              ProfileEditorState,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(_$args.$1, passwordOnly: _$args.passwordOnly),
    );
  }
}
