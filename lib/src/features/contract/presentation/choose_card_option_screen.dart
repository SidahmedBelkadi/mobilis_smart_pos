import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_elevated_button_text.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/permissions_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';

class ChooseCardOptionScreen extends StatefulWidget {
  const ChooseCardOptionScreen({super.key});

  @override
  State<ChooseCardOptionScreen> createState() => _ChooseCardOptionScreenState();
}

class _ChooseCardOptionScreenState extends State<ChooseCardOptionScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: context.height,
          width: context.width,
          padding: EdgeInsets.all(20.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "chooseCard".tr(context),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              Lottie.asset(AppImages.chooseScanAnimation,
                  height: 320.h, width: 320.w),
              SizedBox(height: 32.h),
              Column(
                children: [
                  AppElevatedButtonWithText(
                    text: "identityCard".tr(context),
                    onPressed: () async {
                      bool hasPermission = await _requestCameraPermission();
                      if (hasPermission) {
                        Navigator.of(context).pushNamed(Routes.mrzPreparation,
                            arguments: {'isPassport': false});
                      } else {
                        await _showPermissionDeniedDialog(context);
                      }
                    },
                  ),
                  SizedBox(height: 16.h),
                  AppElevatedButtonWithText(
                    text: "passport".tr(context),
                    onPressed: () async {
                      bool hasPermission = await _requestCameraPermission();
                      if (hasPermission) {
                        Navigator.of(context).pushNamed(Routes.mrzPreparation,
                            arguments: {'isPassport': true});
                      } else {
                        await _showPermissionDeniedDialog(context);
                      }
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('camera_permission_title'.tr(context)),
          content: Text('camera_permission_instruction'.tr(context)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('discard'.tr(context)),
            ),
            TextButton(
              onPressed: () async {
                await PermissionsUtil.openAppSettings();
              },
              child: Text('open_settings'.tr(context)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _requestCameraPermission() async {
    PermissionStatus status =
        await PermissionsUtil.checkPermissionStatus(Permission.camera);
    if (status.isDenied || status.isRestricted) {
      return await PermissionsUtil.requestPermission(Permission.camera);
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return status.isGranted;
  }
}
