import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';

class PersonnelFilesUpdateNotice extends StatelessWidget {
  const PersonnelFilesUpdateNotice({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.width,
          padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 16.sp),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(.1),
            borderRadius: BorderRadius.all(
              Radius.circular(12.sp),
            ),
          ),
          child: Text(
            "upload_instructions".tr(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
