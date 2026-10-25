import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../dependency_injection/injection_container.dart';
import '../../sign_in/data/data_sources/smart_pos_local_storage.dart';

/// Shown when the service was suspended (HTTP 503) while the user was logged in.
/// The session is already cleared: after a short countdown to read the message,
/// the user lands on the sign-in screen.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  static const int countdownSeconds = 10;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  int _remaining = MaintenanceScreen.countdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        _goToSignIn();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _goToSignIn() async {
    // Read: no need to show it again at the next launch
    await serviceLocator<SmartPosLocalStorage>().setMaintenanceLogoutPending(false);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.build_rounded, size: 56, color: AppColors.primary),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'maintenance_title'.tr(context),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'maintenance_message'.tr(context),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _Countdown(remaining: _remaining),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ring emptying second by second until the automatic sign out.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: remaining / MaintenanceScreen.countdownSeconds),
          duration: const Duration(seconds: 1),
          builder: (context, value, _) => SizedBox.square(
            dimension: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.primary.withOpacity(.12),
                  color: AppColors.primary,
                ),
                Center(
                  child: Text(
                    '$remaining',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'maintenance_auto_logout'.tr(context),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
        ),
      ],
    );
  }
}
