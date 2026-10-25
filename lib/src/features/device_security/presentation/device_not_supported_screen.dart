import 'package:flutter/material.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/security/device_security_service.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../dependency_injection/injection_container.dart';

/// Shown when the backend refuses this phone's attestation while enforcing
/// the official app check. [code] is ATTESTATION_INVALID or DEVICE_NOT_SUPPORTED.
class DeviceNotSupportedScreen extends StatefulWidget {
  const DeviceNotSupportedScreen({super.key, required this.code});

  final String code;

  @override
  State<DeviceNotSupportedScreen> createState() => _DeviceNotSupportedScreenState();
}

class _DeviceNotSupportedScreenState extends State<DeviceNotSupportedScreen> {
  final DeviceSecurityService _security = serviceLocator<DeviceSecurityService>();
  late String _code = widget.code;
  bool _checking = false;

  bool get _isUnsupportedPhone => _code == 'DEVICE_NOT_SUPPORTED';

  /// Manual retry: a new key and a new attestation (e.g. after installing the official app).
  Future<void> _retry() async {
    setState(() => _checking = true);
    await _security.reset();
    final enrolled = await _security.ensureEnrolled();
    if (!mounted) return;
    if (enrolled) {
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
      return;
    }
    setState(() {
      _checking = false;
      _code = _security.refusal?.code ?? _code;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('device_check_retry_failed'.tr(context))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isUnsupportedPhone ? Icons.phonelink_erase_rounded : Icons.gpp_bad_rounded,
                  size: 96,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 28),
                Text(
                  (_isUnsupportedPhone ? 'device_not_supported_title' : 'device_not_genuine_title').tr(context),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Text(
                  (_isUnsupportedPhone ? 'device_not_supported_message' : 'device_not_genuine_message').tr(context),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 36),
                FilledButton.icon(
                  onPressed: _checking ? null : _retry,
                  icon: _checking
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: Text('retry'.tr(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
