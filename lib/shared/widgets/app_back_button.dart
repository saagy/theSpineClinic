import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/network/app_routes.dart';
import 'package:spine_clinic_app/features/auth/domain/user_role.dart';
import 'package:spine_clinic_app/features/auth/presentation/auth_providers.dart';

/// A smart back button that pops the screen if there's history,
/// or routes to the user's role-based home screen if there's no history.
class AppBackButton extends ConsumerWidget {
  /// Creates an [AppBackButton].
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: 'Back',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          final role = ref.read(currentUserProvider).value?.role;
          if (role == UserRole.doctor) {
            context.go(AppRoutes.schedule);
          } else {
            context.go(AppRoutes.home);
          }
        }
      },
    );
  }
}
