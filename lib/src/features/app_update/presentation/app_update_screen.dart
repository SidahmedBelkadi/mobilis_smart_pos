import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../dependency_injection/injection_container.dart';
import '../../../services/app_update_installer.dart';

enum _UpdateStage { downloading, needsPermission, installing, readyToInstall, failed }

enum _Failure { download, invalidFile, install }

/// Blocking screen shown when the server has a newer version. The download
/// starts on its own, then the APK is installed without leaving the app.
class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key, required this.currentVersion, required this.newVersion});

  final String currentVersion;
  final String? newVersion;

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> with WidgetsBindingObserver {
  final AppUpdateInstaller _installer = serviceLocator<AppUpdateInstaller>();

  _UpdateStage _stage = _UpdateStage.downloading;
  _Failure _failure = _Failure.download;
  int _received = 0;
  int _total = -1;
  File? _apk;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _download();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _installer.cancelDownload();
    _installer.keepScreenOn(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the "install unknown apps" settings: continue on its own
    if (state == AppLifecycleState.resumed && _stage == _UpdateStage.needsPermission) {
      _install();
    }
  }

  Future<void> _download() async {
    setState(() {
      _stage = _UpdateStage.downloading;
      _received = 0;
      _total = -1;
    });
    _installer.keepScreenOn(true);
    try {
      _apk = await _installer.download(widget.newVersion ?? 'latest', (received, total) {
        if (mounted) {
          setState(() {
            _received = received;
            _total = total;
          });
        }
      });
      _installer.keepScreenOn(false);
      await _install();
    } on DioException catch (e) {
      debugPrint('App update download failed: ${e.type} ${e.error ?? e.message}');
      if (e.type != DioExceptionType.cancel) _fail(_Failure.download);
    } catch (e) {
      debugPrint('App update download failed: $e');
      _fail(_Failure.download);
    }
  }

  Future<void> _install() async {
    final apk = _apk;
    if (!mounted) return;
    if (apk == null) return _download();

    if (!await _installer.canInstall()) {
      if (mounted) setState(() => _stage = _UpdateStage.needsPermission);
      return;
    }

    setState(() => _stage = _UpdateStage.installing);
    try {
      // On success Android replaces the app: this call only returns on cancel
      await _installer.install(apk);
      if (mounted) setState(() => _stage = _UpdateStage.readyToInstall);
    } on PlatformException catch (e) {
      debugPrint('App update install refused: ${e.code} ${e.message}');
      // The file may be corrupt, or not ours: retry with a fresh download
      _apk = null;
      await AppUpdateInstaller.discardDownloads();
      _fail(e.code == 'INSTALL_FAILED' ? _Failure.install : _Failure.invalidFile);
    }
  }

  void _fail(_Failure failure) {
    _installer.keepScreenOn(false);
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _stage = _UpdateStage.failed;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (_stage) {
                _UpdateStage.downloading => _buildDownloading(),
                _UpdateStage.needsPermission => _UpdateLayout(
                    key: const ValueKey('permission'),
                    hero: const _StateIcon(icon: Icons.admin_panel_settings_rounded),
                    title: 'update_title_permission'.tr(context),
                    message: 'update_msg_permission'.tr(context),
                    action: _ActionButton(
                      label: 'update_btn_allow'.tr(context),
                      icon: Icons.check_rounded,
                      onPressed: _installer.openInstallSettings,
                    ),
                  ),
                _UpdateStage.installing => _UpdateLayout(
                    key: const ValueKey('installing'),
                    hero: const _StateIcon(icon: Icons.install_mobile_rounded, busy: true),
                    title: 'update_title_installing'.tr(context),
                    message: 'update_msg_installing'.tr(context),
                  ),
                _UpdateStage.readyToInstall => _UpdateLayout(
                    key: const ValueKey('ready'),
                    hero: const _StateIcon(icon: Icons.download_done_rounded),
                    title: 'update_title_ready'.tr(context),
                    message: 'update_msg_ready'.tr(context),
                    footer: _VersionChip(current: widget.currentVersion, next: widget.newVersion),
                    action: _ActionButton(
                      label: 'update_btn_install'.tr(context),
                      icon: Icons.system_update_rounded,
                      onPressed: _install,
                    ),
                  ),
                _UpdateStage.failed => _buildFailed(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDownloading() {
    final progress = _total > 0 ? (_received / _total).clamp(0.0, 1.0) : null;
    return _UpdateLayout(
      key: const ValueKey('downloading'),
      hero: _ProgressRing(progress: progress),
      title: 'update_title_downloading'.tr(context),
      message: 'update_msg_downloading'.tr(context),
      footer: Column(
        children: [
          _VersionChip(current: widget.currentVersion, next: widget.newVersion),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              _total > 0 ? '${_megabytes(_received)} / ${_megabytes(_total)} MB' : '${_megabytes(_received)} MB',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.secondaryText,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static String _megabytes(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  Widget _buildFailed() {
    final (title, message, retry) = switch (_failure) {
      _Failure.download => ('update_title_download_failed', 'update_msg_download_failed', _download),
      _Failure.invalidFile => ('update_title_invalid', 'update_msg_invalid', _download),
      _Failure.install => ('update_title_install_failed', 'update_msg_install_failed', _install),
    };
    return _UpdateLayout(
      key: ValueKey('failed$_failure'),
      hero: _StateIcon(
        icon: _failure == _Failure.download ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      title: title.tr(context),
      message: message.tr(context),
      action: _ActionButton(label: 'retry'.tr(context), icon: Icons.refresh_rounded, onPressed: retry),
    );
  }
}

/// Hero, title and message centered, the only action pinned at the bottom.
class _UpdateLayout extends StatelessWidget {
  const _UpdateLayout({
    super.key,
    required this.hero,
    required this.title,
    required this.message,
    this.footer,
    this.action,
  });

  final Widget hero;
  final String title;
  final String message;
  final Widget? footer;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  hero,
                  const SizedBox(height: 32),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: AppColors.secondaryText),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 24),
                    footer!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  /// null while the server has not given the file size.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress ?? 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, _) => SizedBox.square(
        dimension: 168,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress == null ? null : value,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.primary.withOpacity(.12),
              color: AppColors.primary,
            ),
            Center(
              child: progress == null
                  ? Icon(Icons.download_rounded, size: 48, color: AppColors.primary)
                  : Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '${(value * 100).round()}%',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.icon, this.color, this.busy = false});

  final IconData icon;
  final Color? color;

  /// Spinning ring around the icon while waiting for Android.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    return SizedBox.square(
      dimension: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(color: tint.withOpacity(.1), shape: BoxShape.circle)),
          if (busy) CircularProgressIndicator(strokeWidth: 3, strokeCap: StrokeCap.round, color: tint),
          Icon(icon, size: 52, color: tint),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.current, required this.next});

  final String current;
  final String? next;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      // Version numbers read left to right in every language
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('v$current', style: style.copyWith(color: AppColors.secondaryText)),
            if (next != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primary),
              ),
              Text('v$next', style: style.copyWith(color: AppColors.primary)),
            ],
          ],
        ),
      ),
    );
  }
}
