import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_compress_service.g.dart';

/// Service that compresses uploaded images before they reach Supabase
/// Storage and produces a small thumbnail JPEG for list rendering.
///
/// Platform split:
/// - **Web (~90% of usage)**: pure-Dart [`image`] package runs both
///   `compressForUpload` and `compressForThumbnail`. No
///   `flutter_image_compress_web` invocation at all — the canvas
///   plugin's `createImageBitmap` rejection path produces a Dart
///   `Error` (not `Exception`) and was crashing uploads on web.
///   The `image` package uses Dart-pure JPEG / PNG / WebP decoders
///   and works identically on every Flutter target. The tradeoff
///   is ~2–4 s of extra CPU per upload on web — accepted.
/// - **Native (iOS/Android/etc.)**: `flutter_image_compress` over
///   the platform channel (faster than pure-Dart decode-encode).
///   Falls back to the `image` package if the native plugin throws.
///
/// All variants strip EXIF by default (matches `flutter_image_compress`
/// `keepExif: false`), removing PHI metadata like GPS coordinates.
///
/// Rule 2 — data-layer work lives in a service, not in widgets.
/// Rule 5 — `Uint8List` byte-typed input / output, no `dynamic`.
class ImageCompressService {
  /// 400 KB threshold above which full-resolution compression is forced.
  static const int _skipCompressionThresholdBytes = 400 * 1024;

  /// Max long-edge bound for the full-resolution JPEG that goes to the
  /// viewer path. 2000 px preserves diagnostic detail for X-ray /
  /// posture photos while bounding per-image size.
  static const int _fullResMaxLongEdge = 2000;
  static const int _fullResQuality = 80;

  /// Square bounds for the thumbnail used in the documents list.
  static const int _thumbMaxEdge = 320;
  static const int _thumbQuality = 75;

  /// Returns bytes ready to upload as the **viewer** copy of an image.
  ///
  /// If [source] is already ≤ 400 KB the source bytes are returned
  /// unchanged — re-encoding a small JPG only inflates artefacting
  /// and burns CPU. The thumbnail is generated separately via
  /// [compressForThumbnail] regardless.
  Future<Uint8List> compressForUpload({
    required Uint8List source,
    required String originalName,
  }) async {
    if (source.length <= _skipCompressionThresholdBytes) return source;

    if (kIsWeb) {
      // Pure-Dart resize via `image` package. Avoids the canvas /
      // createImageBitmap path in `flutter_image_compress_web 0.1.5`
      // which produces uncaught `Error`s on web.
      return _resizeViaImagePackage(
        source: source,
        maxLongEdge: _fullResMaxLongEdge,
        quality: _fullResQuality,
      );
    }

    try {
      final Uint8List compressed = await FlutterImageCompress.compressWithList(
        source,
        minWidth: _fullResMaxLongEdge,
        minHeight: _fullResMaxLongEdge,
        quality: _fullResQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      return compressed;
    } catch (_) {
      // Native plugin failed — fall back to raw bytes so upload still
      // succeeds (the size guards upstream will still hard-reject if
      // raw bytes exceed the 25 MB image / 10 MB PDF cap).
      return source;
    }
  }

  /// Returns a small (≈25 KB) JPEG suitable for list / card
  /// thumbnails — always 320×320 regardless of source dimensions.
  Future<Uint8List> compressForThumbnail({
    required Uint8List source,
    required String originalName,
  }) async {
    if (kIsWeb) {
      return _resizeViaImagePackage(
        source: source,
        maxLongEdge: _thumbMaxEdge,
        quality: _thumbQuality,
      );
    }

    try {
      final Uint8List compressed = await FlutterImageCompress.compressWithList(
        source,
        minWidth: _thumbMaxEdge,
        minHeight: _thumbMaxEdge,
        quality: _thumbQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      return compressed;
    } catch (_) {
      // Plugin failed — degrade to the pure-Dart `image` package
      // path so we still produce a real thumbnail.
      return _resizeViaImagePackage(
        source: source,
        maxLongEdge: _thumbMaxEdge,
        quality: _thumbQuality,
      );
    }
  }

  /// Pure-Dart image decode + resize + JPEG re-encode via the
  /// `image` package. Works identically on every Flutter target
  /// (web, iOS, Android, desktop). If decode fails or the source is
  /// somehow unsupported, returns the original bytes untouched.
  Future<Uint8List> _resizeViaImagePackage({
    required Uint8List source,
    required int maxLongEdge,
    required int quality,
  }) async {
    final img.Image? decoded = img.decodeImage(source);
    if (decoded == null) return source;
    final int longEdge =
        decoded.width >= decoded.height ? decoded.width : decoded.height;
    if (longEdge <= maxLongEdge) {
      return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    }
    final double scale = maxLongEdge / longEdge;
    final img.Image resized = img.copyResize(
      decoded,
      width: (decoded.width * scale).round(),
      height: (decoded.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }
}

/// Singleton provider for the service — kept alive for the app lifetime
/// because the `image` package's decoder caches native image libraries
/// per-thread and recreating on every upload is wasteful.
@Riverpod(keepAlive: true)
ImageCompressService imageCompressService(Ref ref) => ImageCompressService();
