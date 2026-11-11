import 'package:ever_moon/common/app_dimensions.dart';
import 'package:ever_moon/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A field label above its input, with "· không bắt buộc" when [optional]
/// (design: FormNew).
class FieldLabel extends StatelessWidget {
  /// Creates the label.
  const FieldLabel({super.key, required this.text, this.optional = false});

  /// Label text.
  final String text;

  /// Whether the field may stay empty.
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        text: text,
        style: style,
        children: [
          if (optional)
            TextSpan(
              text: ' ${S.of(context).lb_optional_suffix}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Visual and input options of a [LabeledTextField].
class FieldOptions {
  /// Creates the options; the defaults suit a one-line text field.
  const FieldOptions({
    this.optional = false,
    this.hint,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.capitalization = TextCapitalization.none,
  });

  /// Whether the field may stay empty.
  final bool optional;

  /// Text shown while the field is empty.
  final String? hint;

  /// Help under the field.
  final String? helper;

  /// Keyboard to show.
  final TextInputType? keyboardType;

  /// Input filters.
  final List<TextInputFormatter>? inputFormatters;

  /// Minimum visible lines.
  final int? minLines;

  /// Maximum visible lines.
  final int maxLines;

  /// Automatic capitalization.
  final TextCapitalization capitalization;
}

/// A text field with its label above it; screen readers hear the label and
/// the field as one node.
class LabeledTextField extends StatelessWidget {
  /// Creates the field.
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.error,
    this.options = const FieldOptions(),
  });

  /// Label above the field.
  final String label;

  /// Holds the typed text.
  final TextEditingController controller;

  /// Called on every edit.
  final ValueChanged<String> onChanged;

  /// Error under the field, or `null`.
  final String? error;

  /// Visual and input options.
  final FieldOptions options;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppDimensions.space8,
      children: [
        FieldLabel(text: label, optional: options.optional),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: options.keyboardType,
          inputFormatters: options.inputFormatters,
          minLines: options.minLines,
          maxLines: options.maxLines,
          textCapitalization: options.capitalization,
          decoration: InputDecoration(
            hintText: options.hint,
            helperText: options.helper,
            helperMaxLines: 2,
            errorText: error,
          ),
        ),
      ],
    ),
  );
}
