import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/utils/ressources/app_colors.dart';

class CustomAppBottomNavBar extends StatelessWidget {
  const CustomAppBottomNavBar({super.key, this.onTap, this.currentIndex});

  final void Function(int)? onTap;
  final int? currentIndex;

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex ?? 0,
      height: 60.h,
      backgroundColor: Colors.transparent,
      buttonBackgroundColor: AppColors.primary,
      color: AppColors.primary,
      animationDuration: const Duration(milliseconds: 300),
      items: <Widget>[
        Padding(
          padding: EdgeInsets.all(10.sp),
          child: FaIcon(
            FontAwesomeIcons.home,
            size: 20.sp,
            color: Colors.white,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8.sp),
          child: FaIcon(
            FontAwesomeIcons.simCard,
            size: 24.sp,
            color: Colors.white,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(4.sp),
          child: Icon(
            Icons.person,
            size: 28.sp,
            color: Colors.white,
          ),
        ),
      ],
      onTap: onTap,
    );
  }
}
