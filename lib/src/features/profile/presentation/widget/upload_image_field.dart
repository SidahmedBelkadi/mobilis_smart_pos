import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/utils/helpers/media_query_values.dart';
import '../../../../core/utils/ressources/app_colors.dart';

class UploadImageField extends StatelessWidget {
  const UploadImageField(
      {super.key, required this.label, required this.onTap, this.icon = FontAwesomeIcons.plus});

  final String label;
  final void Function()? onTap;
  final IconData icon;

  Future<bool> _checkPermissions(BuildContext context) async {
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      return true;
    } else {
      _showPermissionDeniedDialog(context);
      return false;
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('camera_permission_title'.tr(context)),
          content: Text('camera_permission_instruction'.tr(context)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: Text('open_settings'.tr(context)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('discard'.tr(context)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium!
              .copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: () async {
            final permission = await _checkPermissions(context);
            if (permission) {
              onTap!();
            } else {
              return;
            }
          },
          child: SizedBox(
            width: context.width,
            height: 64.sp,
            child: DottedBorder(
              color: AppColors.primary,
              dashPattern: const [5, 5],
              strokeWidth: 2,
              radius: Radius.circular(12.sp),
              borderType: BorderType.RRect,
              child: Center(
                child: FaIcon(
                  icon,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
