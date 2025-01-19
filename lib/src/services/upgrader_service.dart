import 'dart:convert';

import 'package:flutter/cupertino.dart';
import '../core/api/dio_consumer.dart';
import '../core/api/end_points.dart';
import '../features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../dependency_injection/injection_container.dart' as di;

class UpgraderService {
  final DioConsumer dio;

  const UpgraderService({required this.dio});

  Future<bool> checkIfLastVersionUpdate() async {
    try {
      final storage = di.serviceLocator<SmartPosLocalStorage>();
      // Get the current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      final lastCheckedVersion = storage.getCheckedUpdatedversion();

      // If the version has been updated, clear the flags
      if (isCurrentVersionNewer(currentVersion, lastCheckedVersion)) {
        debugPrint("======== TRUE");

        final DateTime adjustedDate = DateTime.now().subtract(const Duration(minutes: 32));
        storage.saveCheckedUpdateDate(adjustedDate);
      }

      // Get the last checked update date
      final DateTime? lastCheckDate = storage.getCheckedUpdatedDate();
      debugPrint("======= LAST UPDATE CHECK DATE : $lastCheckDate");

      // Check if 60 minute has passed since the last check
      if (lastCheckDate != null && DateTime.now().difference(lastCheckDate).inMinutes < 30) {
        return false;
      }

      // Fetch the latest version from the server
      final response = await dio.get(EndPoints.appVersion);
      debugPrint("RESPONSE : $response");
      final serverVersion = jsonDecode(response)['version'];

      debugPrint("SERVER VERSION $serverVersion");

      // Save the server version
      storage.saveCheckedUpdateVersion(serverVersion);

      // Compare the versions
      if (_isUpdateAvailable(currentVersion, serverVersion)) {
        // Save the current time as the last checked update date
        storage.saveCheckedUpdateDate(DateTime.now());

        // Mark the update as pending
        storage.setUpdatePending(true);

        return true;
      } else {
        storage.setUpdatePending(false);
        storage.saveCheckedUpdateDate(DateTime.now());
        return false;
      }
    } catch (e) {
      debugPrint('Error checking app version: $e');
      return false; // Return false if an error occurs
    }
  }

  bool isCurrentVersionNewer(String currentVersion, String? lastCheckedVersion) {
    if (lastCheckedVersion != null) {
      List<String> currentParts = currentVersion.split('.');
      List<String> lastCheckedParts = lastCheckedVersion.split('.');

      for (int i = 0; i < currentParts.length; i++) {
        int currentPart = int.parse(currentParts[i]);
        int lastCheckedPart = int.parse(lastCheckedParts[i]);

        if (currentPart > lastCheckedPart) {
          return true; // Current version is newer
        } else if (currentPart < lastCheckedPart) {
          return false; // Last checked version is newer
        }
      }

      return false; // Versions are identical
    } else {
      return true;
    }
  }

  bool _isUpdateAvailable(String currentVersion, String serverVersion) {
    // Split versions into parts and compare each part
    List<String> currentParts = currentVersion.split('.');
    List<String> serverParts = serverVersion.split('.');

    for (int i = 0; i < currentParts.length; i++) {
      int currentPart = int.parse(currentParts[i]);
      int serverPart = int.parse(serverParts[i]);

      if (serverPart > currentPart) {
        return true;
      } else if (serverPart < currentPart) {
        return false;
      }
    }
    return false;
  }
}
