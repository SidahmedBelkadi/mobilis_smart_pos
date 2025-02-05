import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeIcon extends StatelessWidget {
  const HomeIcon({
    super.key,
    required this.image,
    required this.title,
    this.onTap,
    this.isDisabled = false,
  });

  final String image;
  final String title;
  final void Function()? onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Image.asset(image, height: 100.sp, width: 120.sp),
          // SizedBox(height: 8.sp),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
