import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
