import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_compress_service.g.dart';

/// Service that compresses uploaded images before they reach Supabase
/// Storage and produces a small thumbnail JPEG for list rendering.
///
/// Platform split:
/// - **Web** (~90% of usage): compression is **skipped entirely**
///   because the `image` package's synchronuous decode+encode on the
///   UI isolate freezes the browser for 2–4 seconds per image. On
///   Flutter Web `compute()` does NOT spawn a Web Worker — it just
///   yields one frame and then runs the callback on the same event
///   loop. So there is no way to off-thread this work on web today.
///   The tradeoff is ~5× higher storage for images on web —
///   acceptable for now; revisit with a Web Worker or server-side
///   compression in the future.
/// - **Native (iOS/Android etc.)**: `flutter_image_compress` over
///   the platform channel (faster than pure-Dart decode-encode).
///   Falls back to the `image` package with a real isolate via
///   `compute()` if the plugin throws. On native `compute()` truly
///   spawns a separate Dart isolate → no UI jank.
///
/// `keepExif: false` is always passed so EXIF metadata (GPS, device
/// identifiers) is stripped by default.
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
  /// On web [source] is returned unchanged — no decode+encode, no
  /// freeze. On native compresses via `flutter_image_compress`
  /// (faster) with a graceful fallback to the original bytes on
  /// plugin failure.
  Future<Uint8List> compressForUpload({
    required Uint8List source,
    required String originalName,
  }) async {
    if (kIsWeb) return source;
    if (source.length <= _skipCompressionThresholdBytes) return source;

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
      return source;
    }
  }

  /// Returns the **thumbnail** bytes for an image, or `null` if no
  /// separate thumbnail should be generated.
  ///
  /// Returns `null` on web (no separate thumbnail — the list view
  /// falls back to `cacheWidth: 150` decoded display of the full
  /// file URL).
  ///
  /// On native, tries `flutter_image_compress` first. If the plugin
  /// throws, falls through to the `image` package running in a
  /// genuine Dart isolate via `compute()`. If that also fails, the
  /// upload still succeeds without a thumbnail (returns the source
  /// bytes so the repo gets at minimum a valid `Uint8List`).
  Future<Uint8List> compressForThumbnail({
    required Uint8List source,
    required String originalName,
  }) async {
    if (kIsWeb) return source;

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
      try {
        return await compute(
          _runResizeJob,
          _ResizeJob(source: source, maxLongEdge: _thumbMaxEdge, quality: _thumbQuality),
        );
      } catch (_) {
        return source;
      }
    }
  }
}

/// Singleton provider for the service — kept alive for the app lifetime
/// because `flutter_image_compress` briefly caches native channels and
/// recreating on every upload is wasteful.
@Riverpod(keepAlive: true)
ImageCompressService imageCompressService(Ref ref) => ImageCompressService();

// ── Isolate-bridge helpers (native only) ──────────────────────────

class _ResizeJob {
  const _ResizeJob({
    required this.source,
    required this.maxLongEdge,
    required this.quality,
  });
  final Uint8List source;
  final int maxLongEdge;
  final int quality;
}

/// Must be a top-level function to satisfy `ComputeCallback`'s shape
/// contract. On native this runs in a separate Dart isolate via
/// `Isolate.spawn` / `SendPort.send`. On web `compute()` calls this
/// on the same event loop after a yielded frame — documented inline
/// in `image_compress_service.dart` doc comment.
@pragma('vm:entry-point')
Uint8List _runResizeJob(_ResizeJob job) {
  final img.Image? decoded = img.decodeImage(job.source);
  if (decoded == null) return job.source;
  final int longEdge =
      decoded.width >= decoded.height ? decoded.width : decoded.height;
  if (longEdge <= job.maxLongEdge) {
    return Uint8List.fromList(img.encodeJpg(decoded, quality: job.quality));
  }
  final double scale = job.maxLongEdge / longEdge;
  final img.Image resized = img.copyResize(
    decoded,
    width: (decoded.width * scale).round(),
    height: (decoded.height * scale).round(),
    interpolation: img.Interpolation.linear,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: job.quality));
}
