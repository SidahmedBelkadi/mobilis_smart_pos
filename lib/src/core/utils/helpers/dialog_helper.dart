import 'package:flutter/material.dart';
import 'media_query_values.dart';

import '../ressources/app_colors.dart';
import 'app_localization_helper.dart';

abstract class AppDialog {
  static void showCustomAppDialog({
    required String title,
    required String content,
    required BuildContext context,
    String acceptName = "accept",
    String discardName = "discard",
    void Function()? onPressed,
    void Function()? onCancelPressed,
    isLoading = false,
    bool barrierDismissible = false,
  }) {
    showDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: context.isDarkMode ? AppColors.darkerGrey : Colors.white,
            title: Text(
              title,
              textAlign: TextAlign.center,
            ),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(discardName.tr(context)),
              ),
              TextButton(
                onPressed: onPressed,
                child: Text(acceptName.tr(context),
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<bool?> showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Exit App"),
          content: const Text("Do you really want to exit app"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                "yes",
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
