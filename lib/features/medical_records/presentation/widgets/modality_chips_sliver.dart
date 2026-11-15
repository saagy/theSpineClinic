library;

import 'package:flutter/material.dart';
import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/features/medical_records/domain/modality_type.dart';
import 'package:spine_clinic_app/features/medical_records/presentation/widgets/modality_chip_selector.dart';

/// Keeps the modality chips reachable while their cards scroll beneath them.
/// Short windows scroll the chips away, since they would cover the form.
class ModalityChipsSliver extends StatelessWidget {
  const ModalityChipsSliver({
    super.key,
    required this.chipsKey,
    required this.selectedModalities,
    required this.onToggle,
  });

  final GlobalKey chipsKey;
  final Set<ModalityType> selectedModalities;
  final ValueChanged<ModalityType> onToggle;

  static bool isPinned(BuildContext context) =>
      MediaQuery.sizeOf(context).height >= AppSizes.pinnedModalityChipsMinWindowHeight;

  @override
  Widget build(BuildContext context) {
    final chips = ColoredBox(
      key: chipsKey,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16, vertical: AppSizes.p8),
        child: ModalityChipSelector(selectedModalities: selectedModalities, onToggle: onToggle),
      ),
    );
    return isPinned(context) ? PinnedHeaderSliver(child: chips) : SliverToBoxAdapter(child: chips);
  }
}

const Duration _revealDuration = Duration(milliseconds: 240);

/// Brings a card that doesn't fit on screen to just below the chips. Cards can
/// be taller than the space available, so its title is what must stay visible.
void revealModalityCard(BuildContext card, BuildContext chips) {
  final scrollable = Scrollable.of(card);
  final viewport = scrollable.context.findRenderObject()! as RenderBox;
  final cardBox = card.findRenderObject()! as RenderBox;
  final cardTop = viewport.globalToLocal(cardBox.localToGlobal(Offset.zero)).dy;
  if (cardTop + cardBox.size.height <= viewport.size.height) return;

  final pinnedHeight = ModalityChipsSliver.isPinned(card) ? chips.size!.height : 0.0;
  scrollable.position.moveTo(
    scrollable.position.pixels + cardTop - pinnedHeight,
    duration: MediaQuery.disableAnimationsOf(card) ? Duration.zero : _revealDuration,
    curve: Curves.easeOutCubic,
  );
}
