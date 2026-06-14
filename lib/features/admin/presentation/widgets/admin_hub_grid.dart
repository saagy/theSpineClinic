/// 2-column admin hub grid with navigation cards.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spine_clinic_app/core/constants/app_colors.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/section_card.dart';

/// The 2×2 admin navigation grid.
class AdminHubGrid extends StatelessWidget {
  const AdminHubGrid({super.key, required this.destinations});
  final List<HubDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSizes.p16,
      mainAxisSpacing: AppSizes.p16,
      childAspectRatio: 0.85,
      children: destinations
          .map((d) => _HubCard(
                title: d.title,
                subtitle: d.subtitle,
                icon: d.icon,
                onTap: () => context.push(d.route),
              ))
          .toList(),
    );
  }
}

/// Describes a single admin hub navigation tile.
class HubDestination {
  const HubDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r8)),
        child: SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: AppSizes.iconLarge),
              const SizedBox(height: AppSizes.p12),
              Text(title,
                  style: AppTextStyles.bodyBold
                      .copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSizes.p4),
              Text(subtitle,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
