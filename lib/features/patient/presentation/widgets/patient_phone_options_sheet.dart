/// Bottom-sheet helper that lets users call or copy a patient's phone number
/// from the patient details screen.
///
/// Rule 1 — under 200 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spine_clinic_app/core/constants/app_sizes.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/core/constants/app_text_styles.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Available actions for the phone number bottom sheet.
enum PhoneAction { call, copy }

/// Bottom-sheet for selecting call or copy actions on a phone number.
class PatientPhoneOptionsSheet extends StatelessWidget {
  const PatientPhoneOptionsSheet({
    super.key,
    required this.phoneNumber,
    required this.onCall,
    required this.onCopy,
  });

  final String phoneNumber;
  final VoidCallback onCall;
  final VoidCallback onCopy;

  /// Shows the bottom sheet and triggers the corresponding action.
  static Future<void> show(BuildContext context, String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return;

    final PhoneAction? action = await showModalBottomSheet<PhoneAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withAlpha(0),
      elevation: 0,
      builder: (sheetContext) => _SheetChrome(
        phoneNumber: phoneNumber,
        onCall: () => Navigator.of(sheetContext).pop(PhoneAction.call),
        onCopy: () => Navigator.of(sheetContext).pop(PhoneAction.copy),
      ),
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case PhoneAction.call:
        final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
        final bool launched = await canLaunchUrl(uri) &&
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          // Fallback to copying if the dialer cannot be launched
          await Clipboard.setData(ClipboardData(text: phoneNumber));
          if (context.mounted) {
            AppSnackbar.show(
              context,
              message: AppStrings.phoneCopied,
              variant: AppSnackbarVariant.success,
            );
          }
        }
      case PhoneAction.copy:
        await Clipboard.setData(ClipboardData(text: phoneNumber));
        if (context.mounted) {
          AppSnackbar.show(
            context,
            message: AppStrings.phoneCopied,
            variant: AppSnackbarVariant.success,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) => _SheetChrome(
        phoneNumber: phoneNumber,
        onCall: onCall,
        onCopy: onCopy,
      );
}

class _SheetChrome extends StatelessWidget {
  const _SheetChrome({
    required this.phoneNumber,
    required this.onCall,
    required this.onCopy,
  });

  final String phoneNumber;
  final VoidCallback onCall;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.r16),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.p20,
          vertical: AppSizes.p16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSizes.handleWidth,
                height: AppSizes.handleHeight,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius:
                      const BorderRadius.all(Radius.circular(AppSizes.p2)),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.p12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
              child: Text(
                phoneNumber,
                style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
              ),
            ),
            const SizedBox(height: AppSizes.p8),
            _PhoneOption(
              icon: Icons.phone_outlined,
              label: AppStrings.call,
              onTap: onCall,
              iconColor: cs.primary,
            ),
            const SizedBox(height: AppSizes.p8),
            _PhoneOption(
              icon: Icons.copy_outlined,
              label: AppStrings.copyPhone,
              onTap: onCopy,
              iconColor: cs.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneOption extends StatelessWidget {
  const _PhoneOption({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(AppSizes.r12)),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tappableMin),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: AppSizes.iconDefault),
              const SizedBox(width: AppSizes.p12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyBold.copyWith(color: cs.onSurface),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.iconDefault,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
