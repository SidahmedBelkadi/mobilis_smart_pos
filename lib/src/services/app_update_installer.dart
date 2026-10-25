import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../core/api/end_points.dart';

/// Result of handing the APK to the Android installer.
enum AppInstallResult { installed, cancelled }

/// Downloads the APK published on our server and installs it through Android,
/// without leaving the app.
class AppUpdateInstaller {
  static const MethodChannel _channel = MethodChannel('smartpos/app_update');

  /// Own client, used only for the APK (no token sent).
  ///
  /// The server certificate is not checked here: the APK signature is. Android
  /// only installs a file signed with our key, so a file altered on the way is
  /// rejected (see AppUpdaterPlugin). API calls keep the strict TLS check.
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 2),
  ))
    ..httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()..badCertificateCallback = (_, __, ___) => true,
    );
  CancelToken? _cancelToken;

  /// Downloads the APK of [version] into the app cache. A complete download of
  /// the same version is reused, so installing again after a cancel is instant.
  Future<File> download(String version, void Function(int received, int total) onProgress) async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/app_updates');
    final apk = File('${dir.path}/smartpos-$version.apk');
    if (await apk.exists()) return apk;

    // Older downloads are useless now
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);

    final partial = File('${apk.path}.part');
    _cancelToken = CancelToken();
    await _dio.download(
      EndPoints.downloadApk,
      partial.path,
      onReceiveProgress: onProgress,
      cancelToken: _cancelToken,
      options: Options(headers: {HttpHeaders.cacheControlHeader: 'no-cache'}),
    );
    return partial.rename(apk.path);
  }

  void cancelDownload() => _cancelToken?.cancel();

  /// Deletes downloaded APKs, e.g. after the installer rejected one.
  Future<void> discardDownloads() async {
    final dir = Directory('${(await getTemporaryDirectory()).path}/app_updates');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// "Install unknown apps" must be allowed once for our app.
  Future<bool> canInstall() async => await _channel.invokeMethod<bool>('canInstall') ?? false;

  Future<void> openInstallSettings() => _channel.invokeMethod('openInstallSettings');

  /// Keeps the screen on during a long download, so the phone does not sleep.
  Future<void> keepScreenOn(bool on) async {
    try {
      await _channel.invokeMethod('keepScreenOn', {'on': on});
    } on PlatformException catch (_) {}
  }

  /// Throws a [PlatformException] whose code is APK_INVALID, APK_WRONG_APP,
  /// APK_WRONG_SIGNATURE or INSTALL_FAILED.
  Future<AppInstallResult> install(File apk) async {
    final result = await _channel.invokeMethod<String>('install', {'path': apk.path});
    return result == 'INSTALLED' ? AppInstallResult.installed : AppInstallResult.cancelled;
  }
}
