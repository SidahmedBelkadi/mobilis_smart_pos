import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import '../../utils/enums/input_type.dart';
import '../../utils/ressources/app_colors.dart';
import '../../validation/validator.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    this.hint,
    this.label,
    this.textEditingController,
    this.suffixIcon,
    this.isObsecure = false,
    this.suffixIconSize = 24,
    this.maxLines = 1,
    this.minLines = 1,
    this.filled = false,
    this.fillColor = const Color.fromARGB(255, 208, 238, 187),
    this.onSuffixTap,
    this.readOnly = false,
    this.isBold = false,
    this.validationType = InputType.NAME,
    this.isRequired = true,
    this.keyboardType = TextInputType.text,
    this.prefixText = '',
    this.suffixText = '',
    this.enabled = true,
    this.disabledValue,
    this.isLatinOnly = false,
  });

  final String? hint;
  final String? label;
  final TextEditingController? textEditingController;
  final dynamic suffixIcon;
  final bool isObsecure;
  final double suffixIconSize;
  final int maxLines;
  final int minLines;
  final bool filled;
  final Color fillColor;
  final void Function()? onSuffixTap;
  final bool readOnly;
  final bool isBold;
  final InputType validationType;
  final bool isRequired;
  final TextInputType keyboardType;
  final String prefixText;
  final String suffixText;
  final bool enabled;
  final String? disabledValue;
  final bool isLatinOnly;

  @override
  Widget build(BuildContext context) {
    if (!enabled && textEditingController != null && disabledValue != null) {
      textEditingController!.text = disabledValue!;
    }

    // Determine text direction
    final textDirection = Directionality.of(context);

    return TextFormField(
      obscureText: isObsecure,
      readOnly: readOnly || !enabled,
      controller: textEditingController,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      enabled: enabled,
      style: !isBold
          ? Theme.of(context).textTheme.bodySmall!.copyWith(
                color: context.isDarkMode ? Colors.white : AppColors.secondaryText,
              )
          : Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: context.isDarkMode ? Colors.white : AppColors.secondaryText,
              ),
      textDirection: textDirection,
      textAlign: textDirection == TextDirection.rtl ? TextAlign.right : TextAlign.left,
      inputFormatters: _getInputFormatters(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText != '' ? prefixText : null,
        suffixText: suffixText != '' ? suffixText : null,
        labelStyle: isBold
            ? Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: context.isDarkMode ? Colors.white : AppColors.secondaryText,
                )
            : null,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: suffixIcon != null ? _buildSuffixIcon() : null,
        filled: filled,
        fillColor: filled ?  context.isDarkMode ? AppColors.darkGrey :  const Color.fromARGB(255, 208, 238, 187) : null,
        border: filled ? _buildOutlineInputBorder( fillColor) : null,
        enabledBorder: filled ? _buildOutlineInputBorder(fillColor) : null,
        focusedBorder: filled ? _buildOutlineInputBorder(fillColor) : null,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) => Validator.validate(
        context: context,
        value: value ?? '',
        type: validationType,
        isRequired: isRequired,
      ),
    );
  }

  List<TextInputFormatter> _getInputFormatters() {
    if (isLatinOnly) {
      return [
        FilteringTextInputFormatter.allow(
          RegExp(r'[A-Za-z0-9\sÀ-ÿ]'),
        ), // Allow Latin characters (including accents), digits, and spaces
      ];
    }

    if (validationType == InputType.PHONE) {
      return [
        FilteringTextInputFormatter.digitsOnly,
        PhoneNumberFormatter(),
      ];
    } else {
      return [];
    }
  }

  InputBorder _buildOutlineInputBorder(Color color) {
    return label != null
        ? UnderlineInputBorder(
            borderSide: BorderSide(color: color),
            borderRadius: BorderRadius.circular(12.sp),
          )
        : OutlineInputBorder(
            borderSide: BorderSide(color: color),
            borderRadius: BorderRadius.circular(12.sp),
          );
  }

  Widget _buildSuffixIcon() {
    if (suffixIcon is IconData) {
      return GestureDetector(
        onTap: onSuffixTap,
        child: Icon(
          suffixIcon as IconData,
          size: suffixIconSize.sp,
          color: AppColors.primary,
        ),
      );
    } else if (suffixIcon is String) {
      return GestureDetector(
        onTap: onSuffixTap,
        child: Image.asset(
          suffixIcon as String,
          width: suffixIconSize.sp,
          height: suffixIconSize.sp,
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove any existing spaces
    String newText = newValue.text.replaceAll(' ', '');

    // Add space after the first digit and then every 2 digits
    String formattedText = '';
    for (int i = 0; i < newText.length; i++) {
      if (i == 1 || (i > 1 && (i - 1) % 2 == 0)) {
        formattedText += ' ';
      }
      formattedText += newText[i];
    }

    // Adjust the cursor position
    int newOffset = formattedText.length;
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
