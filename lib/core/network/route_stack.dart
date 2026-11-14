import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Locations of the open pages, bottom first, including pages pushed inside
/// the app shell. Empty outside a router.
List<String> openPageLocations(BuildContext context) {
  final GoRouter? router = GoRouter.maybeOf(context);
  return router == null ? const [] : _flatten(router.routerDelegate.currentConfiguration.matches);
}

List<String> _flatten(List<RouteMatchBase> matches) => [
  for (final match in matches)
    if (match is ShellRouteMatch) ..._flatten(match.matches) else match.matchedLocation,
];

/// The location of the page directly under the top one, if any.
String? pageBelowTop(BuildContext context) {
  final List<String> pages = openPageLocations(context);
  return pages.length < 2 ? null : pages[pages.length - 2];
}
