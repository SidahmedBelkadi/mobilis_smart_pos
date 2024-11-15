import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';

class ChangePasswordTile extends StatelessWidget {
  const ChangePasswordTile({
    super.key,
    this.onTap,
  });

  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.sp),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          FontAwesomeIcons.userShield,
          color: AppColors.secondary,
          size: 16.sp,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("change_password".tr(context),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
