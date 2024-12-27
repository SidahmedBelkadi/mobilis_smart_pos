import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';

class OfferItem extends StatelessWidget {
  const OfferItem({
    super.key,
    required this.title,
    required this.price,
    this.onTap,
    this.isSelected = false,
  });

  final String title;
  final String price;
  final void Function()? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.sp),
        padding: EdgeInsets.symmetric(vertical: 10.sp),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(10.sp),
          ),
        ),
        child: ListTile(
          title: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text(
              //   price,
              //   style: Theme.of(context).textTheme.bodyMedium,
              // ),
              if (isSelected)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 8.sp,
                    ),
                    Container(
                      padding: EdgeInsets.all(5.sp),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.all(Radius.circular(12.sp)),
                      ),
                      child: Icon(
                        FontAwesomeIcons.check,
                        size: 16.sp,
                        color: Colors.white,
                      ),
                    )
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
