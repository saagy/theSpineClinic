part of 'router.dart';

/// Redirects an active session immediately if the account is deactivated.
class _SessionGuard extends ConsumerWidget {
  const _SessionGuard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Staff?>>(currentUserProvider, (previous, next) {
      final Staff? prevUser = previous?.value;
      final Staff? nextUser = next.value;
      if (prevUser != null &&
          prevUser.isActive &&
          nextUser != null &&
          !nextUser.isActive) {
        context.go(AppRoutes.login);
      }
    });
    return child;
  }
}
