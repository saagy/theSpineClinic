/// Pinned sliver delegate wrapping the tab bar.
library;

import 'package:flutter/material.dart';

class PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  PinnedTabBarDelegate({required this.tabBar, required this.bgColor});
  final Widget tabBar;
  final Color bgColor;

  @override
  double get minExtent => _tabBarHeight;
  @override
  double get maxExtent => _tabBarHeight;
  static const double _tabBarHeight = 48;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: bgColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(PinnedTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar || bgColor != oldDelegate.bgColor;
}
