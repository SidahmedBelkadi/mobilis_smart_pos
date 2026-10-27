import 'package:flutter/material.dart';

import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';

/// Covers the screen while the client is being checked after the ID scan.
class CheckClientOverlay extends StatelessWidget {
  const CheckClientOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        ModalBarrier(color: Colors.black.withOpacity(.35), dismissible: false),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 26,
                  child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'check_client_loading'.tr(context),
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Translation key of the explanation for a refusal code from check-client.
String checkClientRefusalMessageKey(String code) => switch (code) {
      'CLIENT_BLACKLISTED' => 'check_client_blacklisted',
      'DOCUMENT_EXPIRED' => 'check_client_document_expired',
      'CLIENT_HAS_REACHED_SIM_LIMIT' => 'check_client_sim_limit',
      'THIS_MINOR_IS_PRESUMING_TO_BE_ADULT' => 'THIS_MINOR_IS_PRESUMING_TO_BE_ADULT',
      _ => code,
    };

/// Blocking dialog: the result of the check, with one or two actions.
Future<void> showCheckClientDialog({
  required BuildContext context,
  required bool refused,
  required String message,
  required VoidCallback onLeave,
  VoidCallback? onRetry,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final color = refused ? theme.colorScheme.error : AppColors.primary;
      return PopScope(
        canPop: false,
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: color.withOpacity(.12), shape: BoxShape.circle),
                    child: Icon(refused ? Icons.person_off_rounded : Icons.wifi_off_rounded, size: 36, color: color),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  (refused ? 'check_client_refused_title' : 'check_client_failed_title').tr(dialogContext),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: AppColors.secondaryText),
                ),
                const SizedBox(height: 24),
                if (onRetry != null) ...[
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        onRetry();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('retry'.tr(dialogContext)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: 48,
                  child: onRetry == null
                      ? FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: onLeave,
                          child: Text('check_client_back_home'.tr(dialogContext)),
                        )
                      : TextButton(
                          onPressed: onLeave,
                          child: Text('check_client_back_home'.tr(dialogContext)),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
