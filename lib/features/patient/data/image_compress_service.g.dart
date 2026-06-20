// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_compress_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton provider for the service — kept alive for the app lifetime
/// because `flutter_image_compress` briefly caches native channels and
/// recreating on every upload is wasteful.

@ProviderFor(imageCompressService)
final imageCompressServiceProvider = ImageCompressServiceProvider._();

/// Singleton provider for the service — kept alive for the app lifetime
/// because `flutter_image_compress` briefly caches native channels and
/// recreating on every upload is wasteful.

final class ImageCompressServiceProvider
    extends
        $FunctionalProvider<
          ImageCompressService,
          ImageCompressService,
          ImageCompressService
        >
    with $Provider<ImageCompressService> {
  /// Singleton provider for the service — kept alive for the app lifetime
  /// because `flutter_image_compress` briefly caches native channels and
  /// recreating on every upload is wasteful.
  ImageCompressServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'imageCompressServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$imageCompressServiceHash();

  @$internal
  @override
  $ProviderElement<ImageCompressService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ImageCompressService create(Ref ref) {
    return imageCompressService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImageCompressService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImageCompressService>(value),
    );
  }
}

String _$imageCompressServiceHash() =>
    r'7e6c6224b1e52894c8d2d28c1db5e43b62ceb1d3';
