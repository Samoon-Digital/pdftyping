import 'package:flutter/material.dart';

class SuggestibleInputField extends StatelessWidget {
  final TextEditingController controller;
  final String fieldKey;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final bool enableSuggestions;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const SuggestibleInputField({
    super.key,
    required this.controller,
    required this.fieldKey,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.readOnly = false,
    this.enableSuggestions = true,
    this.onTap,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'NotoSansDevanagari', fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(fontFamily: 'NotoSansDevanagari'),
          hintStyle: TextStyle(
            fontFamily: 'NotoSansDevanagari',
            color: Colors.grey.shade400,
          ),
          suffixIcon: suffixIcon == null
              ? null
              : GestureDetector(onTap: onTap, child: suffixIcon),
        ),
        validator:
            validator ??
            (v) => (v == null || v.trim().isEmpty)
                ? 'कृपया सभी फ़ील्ड भरें'
                : null,
      ),
    );
  }
}
