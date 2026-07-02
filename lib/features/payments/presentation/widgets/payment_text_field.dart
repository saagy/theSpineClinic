import 'package:flutter/material.dart';
import 'package:spine_clinic_app/features/payments/presentation/widgets/payment_input_decoration.dart';

class PaymentTextField extends StatelessWidget {
  const PaymentTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.focusNode,
    this.hintText,
    this.suffixText,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String? hintText;
  final String? suffixText;
  final bool enabled;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: paymentInputDecoration(
        context,
        labelText: labelText,
        hintText: hintText,
        suffixText: suffixText,
      ),
    );
  }
}
