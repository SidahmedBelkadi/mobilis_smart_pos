import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/utils/ressources/app_colors.dart';

class SimCardSlotTile extends StatelessWidget {
  const SimCardSlotTile({
    super.key,
    this.onTap,
    required this.title,
    required this.icon,
    this.isSelected = false,
  });

  final Function()? onTap;
  final String title;
  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.sp),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: AppColors.secondary,
          size: 16.sp,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            if (isSelected)
              Container(
                padding: EdgeInsets.all(5.sp),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.all(
                    Radius.circular(12.sp),
                  ),
                ),
                child: Icon(
                  FontAwesomeIcons.check,
                  color: Colors.white,
                  size: 14.sp,
                ),
              )
          ],
        ),
      ),
    );
  }
}
