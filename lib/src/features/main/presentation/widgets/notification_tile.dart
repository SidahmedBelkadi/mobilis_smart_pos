import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/ressources/app_colors.dart';

class NotificationPermissionTile extends StatefulWidget {
  const NotificationPermissionTile({super.key});

  @override
  State<NotificationPermissionTile> createState() => _NotificationPermissionTileState();
}

class _NotificationPermissionTileState extends State<NotificationPermissionTile> {
  bool _isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  // Method to check the notification permission status
  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    setState(() {
      _isNotificationEnabled = status.isGranted;
    });
  }

  // Method to request the notification permission
  Future<void> _requestNotificationPermission(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      setState(() {
        _isNotificationEnabled = status.isGranted;
      });
    } else {
      setState(() {
        _isNotificationEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 10.0.sp),
      child: ListTile(
        onTap: () {},
        leading: Icon(
          FontAwesomeIcons.bell,
          size: 16.sp,
          color: AppColors.secondary,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "notifications".tr(context),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Switch(
              value: _isNotificationEnabled,
              onChanged: (value) {
                _requestNotificationPermission(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
