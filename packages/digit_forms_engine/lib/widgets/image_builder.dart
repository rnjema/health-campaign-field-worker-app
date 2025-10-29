part of 'json_schema_builder.dart';

class JsonSchemaImageBuilder extends JsonSchemaBuilder<String> {
  final bool isMultiSelect;
  const JsonSchemaImageBuilder({
    required super.formControlName,
    required super.form,
    super.key,
    super.value,
    super.label,
    super.validations,
    super.readOnly,
    super.isRequired,
    this.isMultiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.digitTextTheme(context);
    final loc = FormLocalization.of(context);
    final validationMessages = buildValidationMessages(validations, loc);

    // Access defaultValues from Provider to replace {value} placeholders
    final defaultValues = context.read<Map<String, dynamic>>();

    // Resolve label by replacing {value} with defaultValues
    final resolvedLabel =
        _resolveLabelPlaceholders(loc.translate(label ?? ''), defaultValues);

    return ReactiveWrapperField(
      formControlName: formControlName,
      validationMessages: validationMessages,
      builder: (field) {
        return ImageUploader(
          label: label,
          allowMultiples: isMultiSelect,
          onImagesSelected: (selectedImages) async {
            if (selectedImages.isEmpty) {
              // Clear the form control if no images
              form.control(formControlName).value = null;
              return;
            }

            try {
              // Compress all selected images
              final compressedImages = await ImageCompressionUtils.compressMultiple(
                selectedImages,
                maxWidth: 1920,
                maxHeight: 1920,
                quality: 85,
              );

              // Store as list of maps with name and base64 data
              // For single image, store as single map, for multiple, store as list
              if (isMultiSelect) {
                form.control(formControlName).value = compressedImages;
              } else {
                // For single image, store just the first image
                form.control(formControlName).value = compressedImages.isNotEmpty
                    ? compressedImages.first
                    : null;
              }

              // Mark as touched for validation
              form.control(formControlName).markAsTouched();
            } catch (e) {
              // Handle compression error
              print('Error compressing images: $e');
              // Optionally show error to user
              form.control(formControlName).setErrors({'compression': 'Failed to compress image'});
            }
          },
        );
      },
    );
  }

  /// Resolves placeholders in label by replacing {key} with values from defaultValues
  String? _resolveLabelPlaceholders(
    String? label,
    Map<String, dynamic> defaultValues,
  ) {
    if (label == null || label.isEmpty) return label;

    // Regular expression to match {key} (single braces)
    final regex = RegExp(r'\{([^}]+)\}');

    return label.replaceAllMapped(regex, (match) {
      final key = match.group(1)?.trim() ?? '';
      if (key.isEmpty) return match.group(0) ?? '';

      // Look up the value in defaultValues
      final value = defaultValues[key];

      // If found, wrap value in ** for bold text
      if (value != null) {
        return '**${value.toString()}**';
      }

      // If not found, return placeholder as-is
      return match.group(0) ?? '';
    });
  }
}
