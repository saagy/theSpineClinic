import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/shared/widgets/refresh_on_return.dart';

void main() {
  testWidgets(
    'entry and browser foreground return trigger; time and rebuilds do not',
    (tester) async {
      var returns = 0;
      Widget screen() => MaterialApp(
        home: RefreshOnReturn(
          onReturn: () => returns++,
          child: const SizedBox(),
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(screen());
      expect(returns, 1);
      await tester.pump(const Duration(minutes: 5));
      await tester.pumpWidget(screen());
      expect(returns, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      expect(returns, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(returns, 2);
      await tester.pumpWidget(const SizedBox());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(returns, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('only the selected schedule subtab refreshes on return', (
    tester,
  ) async {
    var returns = 0;
    Widget screen(bool selected) => MaterialApp(
      home: RefreshOnReturn(
        enabled: selected,
        onReturn: () => returns++,
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(screen(true));
    expect(returns, 1);
    await tester.pumpWidget(screen(false));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(returns, 1);
    await tester.pumpWidget(screen(true));
    expect(returns, 2);
  });

  testWidgets('nested shell routes refresh after returning from a root page', (
    tester,
  ) async {
    var returns = 0;
    final root = GlobalKey<NavigatorState>();
    final router = GoRouter(
      navigatorKey: root,
      routes: [
        ShellRoute(
          builder: (_, _, child) => Scaffold(body: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => RefreshOnReturn(
                onReturn: () => returns++,
                child: const Text('schedule'),
              ),
            ),
            GoRoute(path: '/other', builder: (_, _) => const Text('other')),
          ],
        ),
        GoRoute(
          path: '/detail',
          parentNavigatorKey: root,
          builder: (_, _) => const Scaffold(body: Text('detail')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(returns, 1);
    router.push<void>('/detail');
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(returns, 1); // Hidden nested schedule must not refresh.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('schedule'), findsOneWidget);
    expect(returns, 2);
    router.go('/other');
    await tester.pumpAndSettle();
    expect(returns, 2);
    router.go('/');
    await tester.pumpAndSettle();
    expect(returns, 3);
  });
}
