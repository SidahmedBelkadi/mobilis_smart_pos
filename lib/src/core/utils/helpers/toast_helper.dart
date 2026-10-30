import 'package:flutter/material.dart';
import 'media_query_values.dart';
import 'package:toastification/toastification.dart';

import '../ressources/app_colors.dart';

abstract class AppToasts {
  static final progressBarTheme =
      ProgressIndicatorThemeData(refreshBackgroundColor: AppColors.secondary);

  /// toastification cuts the description at 2 lines: an explicit maxLines shows long messages in full.
  static Widget _description(String message) => Text(message, maxLines: 10);

  static void showSuccessToast({required String message, required BuildContext context}) {
    toastification.show(
      backgroundColor: context.isDarkMode ? Colors.black : Colors.white,
      foregroundColor: context.isDarkMode ? Colors.white : Colors.black,
      context: context,
      description: _description(message),
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      progressBarTheme: progressBarTheme,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
    );
  }

  static void showInfoToast({
    required String message,
    required BuildContext context,
    Function(ToastificationItem)? onAutoCompleteCompleted,
  }) {
    toastification.show(
      backgroundColor: context.isDarkMode ? Colors.black : Colors.white,
      foregroundColor: context.isDarkMode ? Colors.white : Colors.black,
      context: context,
      description: _description(message),
      autoCloseDuration: const Duration(seconds: 5),
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      showProgressBar: true,
      progressBarTheme: const ProgressIndicatorThemeData(
        refreshBackgroundColor: Colors.blueAccent,
        color: Colors.blue,
      ),
      callbacks: ToastificationCallbacks(onAutoCompleteCompleted: onAutoCompleteCompleted),
    );
  }

  static void showErrorToast(
      {required String message,
      Function(ToastificationItem)? onAutoCompleteCompleted,
      required BuildContext context}) {
    toastification.show(
        backgroundColor: context.isDarkMode ? Colors.black : Colors.white,
        foregroundColor: context.isDarkMode ? Colors.white : Colors.black,
        context: context,
        description: _description(message),
        autoCloseDuration: const Duration(seconds: 5),
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        showProgressBar: true,
        progressBarTheme: const ProgressIndicatorThemeData(
          refreshBackgroundColor: Colors.red,
          color: Colors.red,
        ),
        callbacks: ToastificationCallbacks(
          onAutoCompleteCompleted: onAutoCompleteCompleted,
        ));
  }

  static void showWarningToast({required String message, required BuildContext context}) {
    toastification.show(
      backgroundColor: context.isDarkMode ? Colors.black : Colors.white,
      foregroundColor: context.isDarkMode ? Colors.white : Colors.black,
      context: context,
      description: _description(message),
      autoCloseDuration: const Duration(seconds: 5),
      showProgressBar: true,
      progressBarTheme: progressBarTheme,
      type: ToastificationType.warning,
      style: ToastificationStyle.flat,
    );
  }
}
