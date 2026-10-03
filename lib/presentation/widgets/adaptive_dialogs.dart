import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:time_register/l10n/app_localizations.dart';

import '../../core/platform/app_platform.dart';

/// A dialog action: a Cupertino alert action on Apple platforms, a text
/// button (error-colored when destructive) elsewhere.
Widget adaptiveDialogAction(
  BuildContext context, {
  required String label,
  required VoidCallback onPressed,
  bool isDefault = false,
  bool isDestructive = false,
}) {
  if (isApplePlatform) {
    return CupertinoDialogAction(
      isDefaultAction: isDefault,
      isDestructiveAction: isDestructive,
      onPressed: onPressed,
      child: Text(label),
    );
  }
  return TextButton(
    onPressed: onPressed,
    style: isDestructive
        ? TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          )
        : null,
    child: Text(
      label,
      style: isDefault ? const TextStyle(fontWeight: FontWeight.w800) : null,
    ),
  );
}

/// Asks the user to confirm; resolves to true only when they confirm.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showAdaptiveDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        adaptiveDialogAction(
          dialogContext,
          label: l10n.cancel,
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        adaptiveDialogAction(
          dialogContext,
          label: confirmLabel,
          isDefault: !destructive,
          isDestructive: destructive,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Asks for a single value; resolves to the trimmed text, or null when
/// cancelled. [validator] returns an error message or null.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String initialValue,
  String? prefix,
  String? suffix,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  String? Function(String value)? validator,
}) {
  return showAdaptiveDialog<String>(
    context: context,
    builder: (_) => _TextInputDialog(
      title: title,
      message: message,
      initialValue: initialValue,
      prefix: prefix,
      suffix: suffix,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator: validator,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String initialValue;
  final String? prefix;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? Function(String value)? validator;

  const _TextInputDialog({
    required this.title,
    required this.message,
    required this.initialValue,
    required this.prefix,
    required this.suffix,
    required this.keyboardType,
    required this.inputFormatters,
    required this.maxLength,
    required this.validator,
  });

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final error = widget.validator?.call(value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final apple = isApplePlatform;
    final scheme = Theme.of(context).colorScheme;

    final field = apple
        ? CupertinoTextField(
            controller: _controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            maxLength: widget.maxLength,
            textAlign: TextAlign.center,
            prefix: widget.prefix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(widget.prefix!),
                  ),
            suffix: widget.suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(widget.suffix!),
                  ),
            onSubmitted: (_) => _submit(),
          )
        : TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            maxLength: widget.maxLength,
            decoration: InputDecoration(
              prefixText: widget.prefix == null ? null : '${widget.prefix} ',
              suffixText: widget.suffix,
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          );

    return AlertDialog.adaptive(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(widget.message!),
            ),
          // CupertinoAlertDialog has no Material ancestor for the text field.
          apple
              ? field
              : Material(type: MaterialType.transparency, child: field),
          if (apple && _error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(fontSize: 13, color: scheme.error),
              ),
            ),
        ],
      ),
      actions: [
        adaptiveDialogAction(
          context,
          label: l10n.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        adaptiveDialogAction(
          context,
          label: l10n.save,
          isDefault: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}
