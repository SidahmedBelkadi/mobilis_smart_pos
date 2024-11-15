import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'invoice_skeleton.dart';

class SkeletonListView extends StatelessWidget {
  const SkeletonListView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 10,
      itemBuilder: (context, index) => const InvoiceSkeleton(),
      separatorBuilder: (context, index) => SizedBox(height: 16.sp),
    );
  }
}
