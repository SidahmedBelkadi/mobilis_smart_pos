import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/helpers/app_localization_helper.dart';

class NoMoreInvoices extends StatelessWidget {
  const NoMoreInvoices({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(5.sp),
        child: Text(
          "no_more_operations".tr(context),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
