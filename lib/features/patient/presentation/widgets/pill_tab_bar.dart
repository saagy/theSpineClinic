/// Underline tab bar — standard Material 3 style.
///
/// 2px active indicator in primary teal, no filled pill background.
/// Active label: 13px, w500, primary. Inactive: 13px, w400, onSurfaceVariant.
///
/// Rule 15/16 — all colours via Theme.of(context).colorScheme.
library;

import 'package:flutter/material.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';

class UnderlineTabBar extends StatelessWidget {
  const UnderlineTabBar({super.key, required this.tabs});
  final List<Tab> tabs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: TabBar(
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            indicatorColor: cs.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorWeight: 2,
            dividerColor: cs.outlineVariant,
            dividerHeight: 0.5,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
            tabs: tabs,
          ),
        ),
      ),
    );
  }
}
