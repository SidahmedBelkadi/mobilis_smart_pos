import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/utils/enums/invoice_status.dart';
import 'package:mobilis_smart_pos/src/features/invoices/presentation/widgets/invoice_status.dart';

import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../domain/entities/invoice_entity.dart';

class Invoice extends StatelessWidget {
  const Invoice({
    super.key,
    required this.invoiceEntity,
  });

  final InvoiceEntity invoiceEntity;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    InvoiceStatus(
                        invoiceStatus: invoiceEntity.msisdn != null
                            ? InvoiceStatusEnum.success
                            : InvoiceStatusEnum.failed),
                    Text(
                      context.isArabicLocale
                          ? invoiceEntity.formattedInvoiceDateInArabic
                          : invoiceEntity.formattedInvoiceDate,
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
                        invoiceEntity.contractCode,
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
                        invoiceEntity.msisdn == null
                            ? "notAvailable".tr(context)
                            : invoiceEntity.msisdn.toString(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
                        invoiceEntity.iccid == null
                            ? "notAvailable".tr(context)
                            : invoiceEntity.iccid.toString(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
    );
  }
}
