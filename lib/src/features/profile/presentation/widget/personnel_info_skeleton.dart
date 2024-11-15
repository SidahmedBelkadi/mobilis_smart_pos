import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import 'profile_item_field.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PersonalInfoSkeleton extends StatelessWidget {
  const PersonalInfoSkeleton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Column(
        children: [
          SizedBox(height: 32.h),
          ProfileItem(label: "name".tr(context), value: "Sidahmed Belkdai"),
          SizedBox(height: 16.h),
          ProfileItem(label: "enterprise".tr(context), value: "MOBILIS"),
          SizedBox(height: 16.h),
          ProfileItem(label: "msisdn_apn".tr(context), value: "+213687654987"),
          SizedBox(height: 16.h),
          ProfileItem(label: "msisdn_erselli".tr(context), value: "+213687654987"),
          SizedBox(height: 16.h),
          ProfileItem(label: "secret_code".tr(context), value: "8763764", obsecureOption: true),
          SizedBox(height: 16.h),
          ProfileItem(label: "commercial_register".tr(context), value: "RC7682367438276"),
          SizedBox(height: 16.h),
          ProfileItem(label: "nif".tr(context), value: "7248348624"),
          SizedBox(height: 16.h),
          ProfileItem(label: "address".tr(context), value: "Cheraga Alger Boumerdes"),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}
