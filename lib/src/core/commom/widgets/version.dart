import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/helpers/media_query_values.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import package_info_plus

import '../../utils/ressources/app_colors.dart';

class VersionWidget extends StatefulWidget {
  const VersionWidget({super.key});

  @override
  _VersionWidgetState createState() => _VersionWidgetState();
}

class _VersionWidgetState extends State<VersionWidget> {
  String _appVersion = ''; // To store the app version

  @override
  void initState() {
    super.initState();
    _getAppVersion(); // Fetch app version
  }

  Future<void> _getAppVersion() async {
    // Use PackageInfo to get app version
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version; // Set the fetched version
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.primary : AppColors.secondaryLight,
        borderRadius: BorderRadius.all(
          Radius.circular(8.sp),
        ),
        border: Border.all(color: context.isDarkMode ? AppColors.primary : AppColors.secondary),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 4.sp),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.sp),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _appVersion.isNotEmpty ? _appVersion : '1.0.0',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: context.isDarkMode ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
