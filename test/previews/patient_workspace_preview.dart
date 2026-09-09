import 'package:flutter/material.dart';
import '../fixtures/workspace_harness.dart';

/// Standalone production-widget preview with fictional, isolated provider data.
void main() {
  final params = Uri.base.queryParameters;
  runApp(
    WorkspaceHarness(
      role: params['role'] ?? 'doctor',
      dark: params['theme'] == 'dark',
      empty: params['state'] == 'empty',
      paymentError: params['state'] == 'payment-error',
      longName: params['name'] == 'long',
      scale: double.tryParse(params['scale'] ?? '') ?? 1,
    ),
  );
}
