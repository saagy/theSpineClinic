import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spine_clinic_app/core/constants/app_strings.dart';
import 'package:spine_clinic_app/shared/widgets/app_snackbar.dart';

/// Communication helper for launching phone calls and WhatsApp messages.
abstract final class PatientCommunicationHelper {
  /// Initiates a phone call or falls back to clipboard copy.
  static Future<void> callPhone(BuildContext context, String rawPhone) async {
    final phone = rawPhone.trim();
    if (phone.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      await copyPhone(context, phone);
    }
  }

  /// Opens WhatsApp chat or falls back to clipboard copy.
  static Future<void> openWhatsApp(BuildContext context, String rawPhone) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) return;

    final uri = Uri.parse('https://wa.me/$phone');
    final launched = await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && context.mounted) {
      await copyPhone(context, rawPhone);
    }
  }

  /// Copies phone number to clipboard and shows confirmation snackbar.
  static Future<void> copyPhone(BuildContext context, String rawPhone) async {
    final phone = rawPhone.trim();
    if (phone.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: phone));
    if (context.mounted) {
      AppSnackbar.show(
        context,
        message: AppStrings.phoneCopied,
        variant: AppSnackbarVariant.success,
      );
    }
  }
}
