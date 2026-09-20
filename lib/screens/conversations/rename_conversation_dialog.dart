import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';

/// Accessible rename dialog: validates the title, trims whitespace, and
/// cancels safely. Returns the new title, or null when cancelled.
Future<String?> showRenameConversationDialog({
  required BuildContext context,
  String initialTitle = '',
}) {
  final controller = TextEditingController(text: initialTitle)
    ..selection = TextSelection.collapsed(offset: initialTitle.length);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Rename conversation'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Title',
            counterText: '',
          ),
          validator: Validators.validateConversationTitle,
          onFieldSubmitted: (value) {
            if (formKey.currentState!.validate()) {
              Navigator.of(dialogContext).pop(value.trim());
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(dialogContext).pop(controller.text.trim());
            }
          },
          child: const Text('Rename'),
        ),
      ],
    ),
  );
}
