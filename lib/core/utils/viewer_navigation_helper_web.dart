// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Web implementation using browser history.back() to pop cleanly without duplicates.
void closeViewerPlatform(BuildContext context, {String? fallbackLocation}) {
  if (html.window.history.length > 1) {
    html.window.history.back();
  } else if (context.canPop()) {
    context.pop();
  } else if (fallbackLocation != null && fallbackLocation.isNotEmpty) {
    context.go(fallbackLocation);
  }
}
