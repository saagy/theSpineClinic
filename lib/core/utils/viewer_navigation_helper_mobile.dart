import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mobile native implementation for closing a media viewer.
void closeViewerPlatform(BuildContext context, {String? fallbackLocation}) {
  if (context.canPop()) {
    context.pop();
  } else if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  } else if (fallbackLocation != null && fallbackLocation.isNotEmpty) {
    context.go(fallbackLocation);
  }
}
