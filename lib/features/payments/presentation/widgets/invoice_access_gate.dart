import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/domain/staff.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/invoice_access.dart';

/// Shows [builder] only to staff that [allow] admits (by default, the manage
/// capability). Loading, failure and denial render inside [frame] so the app
/// bar stays in place.
class InvoiceManageGate extends ConsumerWidget {
  const InvoiceManageGate({
    super.key,
    required this.frame,
    required this.loading,
    required this.builder,
    this.allow = InvoiceAccess.canManage,
  });
  final Widget Function(Widget body) frame;
  final Widget loading;
  final Widget Function(Staff user) builder;
  final bool Function(Staff? user) allow;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(currentUserProvider).when(
        loading: () => frame(loading),
        error: (error, _) => frame(
          ErrorView(
            exception: AppException.fromSupabaseException(error),
            onRetry: () => ref.invalidate(currentUserProvider),
          ),
        ),
        data: (user) => allow(user)
            ? builder(user!)
            : frame(
                ErrorView(
                  exception: AuthException(
                    code: 'security/blocked',
                    message: AppStrings.invoices.errorDenied,
                    userMessageKey: 'invoice_denied',
                  ),
                ),
              ),
      );
}
