import 'package:flutter/material.dart';

import 'viewer_navigation_helper_stub.dart'
    if (dart.library.html) 'viewer_navigation_helper_web.dart'
    if (dart.library.io) 'viewer_navigation_helper_mobile.dart';

/// Platform-agnostic helper to close full-screen media viewers cleanly.
///
/// On Web, uses `html.window.history.back()` to avoid creating duplicate
/// forward history states, allowing the browser/mobile swipe-back gesture
/// to navigate directly to the previous app screen.
///
/// On Mobile/Desktop, uses standard GoRouter / Navigator pop.
void closeViewer(BuildContext context, {String? fallbackLocation}) {
  closeViewerPlatform(context, fallbackLocation: fallbackLocation);
}
