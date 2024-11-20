import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/enums/invoice_status.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';

class InvoiceStatus extends StatelessWidget {
  const InvoiceStatus({
    super.key,
    required this.invoiceStatus,
  });

  final InvoiceStatusEnum invoiceStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 6.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.sp),
        color: invoiceStatus.backgroundColor,
      ),
      child: Text(
        invoiceStatus.name == "success"
            ? "success".tr(context)
            : invoiceStatus.name == "failed"
                ? "failed".tr(context)
                : "pending".tr(context),
        style: Theme.of(context).textTheme.labelMedium!.copyWith(color: invoiceStatus.color),
      ),
    );
  }
}
