import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/ressources/app_colors.dart';

class CustomFAB extends StatelessWidget {
  const CustomFAB({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.heroTag = 'Hero-Tag',
  });

  final String label;
  final IconData icon;
  final void Function()? onPressed;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      backgroundColor: AppColors.primary,
      onPressed: onPressed,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 5.sp),
          Icon(icon, color: Colors.black),
        ],
      ),
    );
  }
}
