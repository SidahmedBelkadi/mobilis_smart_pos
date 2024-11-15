import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/utils/enums/invoice_status.dart';
import 'invoice_status.dart';

class InvoiceSkeleton extends StatelessWidget {
  const InvoiceSkeleton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Container(
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(12.sp),
          ),
          border: Border.all(color: const Color.fromARGB(255, 207, 218, 199)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const InvoiceStatus(
                        invoiceStatus: InvoiceStatusEnum.skeleton,
                      ),
                      Text(
                        "12/10/2024",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.sp),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "contractLabel".tr(context),
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Flexible(
                        child: Text(
                          "CT0000000T0005",
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.sp),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "msisdn".tr(context),
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Flexible(
                        child: Text(
                          "213661113838",
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.sp),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "iccid".tr(context),
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Flexible(
                        child: Text(
                          "1414666666666666",
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
