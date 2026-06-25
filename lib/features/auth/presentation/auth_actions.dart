/// Shared UI-layer actions for the authenticated staff surface.
///
/// Centralizes plumbing that was previously copy-pasted across the three
/// profile/admin hub screens (sign-out flow, future shared actions).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';
import 'package:spine_clinic_app/shared/widgets/confirmation_dialog.dart';

/// Shows the destructive sign-out confirmation dialog and, on confirm,
/// triggers [AuthNotifier.logout] via the [currentUserProvider].
///
/// Returns the resulting confirm flag (true = user agreed) or null if the
/// dialog was dismissed.
Future<bool?> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => const ConfirmationDialog(
      title: AppStrings.signOut,
      message: AppStrings.confirmSignOut,
      confirmLabel: AppStrings.signOut,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
    ),
  );
  if (confirm == true) {
    await ref.read(currentUserProvider.notifier).logout();
  }
  return confirm;
}
