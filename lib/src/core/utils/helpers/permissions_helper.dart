import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsUtil {
  // Private constructor to prevent instantiation
  PermissionsUtil._();

  // Request a single permission
  static Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  // Request multiple permissions
  static Future<Map<Permission, PermissionStatus>> requestPermissions(
      List<Permission> permissions) async {
    return await permissions.request();
  }

  // Check the status of a single permission
  static Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return await permission.status;
  }

  // Check the status of multiple permissions
  static Future<Map<Permission, PermissionStatus>> checkPermissionsStatus(
      List<Permission> permissions) async {
    Map<Permission, PermissionStatus> statuses = {};
    for (Permission permission in permissions) {
      statuses[permission] = await permission.status;
    }
    return statuses;
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }
}
