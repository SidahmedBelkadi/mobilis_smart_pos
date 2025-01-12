import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/features/invoices/presentation/widgets/retry_activation_widget.dart';
import '../../../../core/utils/enums/invoice_status.dart';
import '../../../../core/utils/helpers/app_localization_helper.dart';
import '../../../../core/utils/helpers/media_query_values.dart';
import '../../domain/entities/invoice_entity.dart';
import 'invoice_status.dart';

class Invoice extends StatelessWidget {
  const Invoice({
    super.key,
    required this.invoiceEntity,
  });

  final InvoiceEntity invoiceEntity;

  InvoiceStatusEnum _filterInvoiceStatus(String status, String? msisdn) {
    String normalizedStatus = status.toLowerCase();

    if (msisdn == null) {
      switch (normalizedStatus) {
        case 'dsa timeout':
        case 'network_failure_treated':
          return InvoiceStatusEnum.failed;
        case 'pending':
          return InvoiceStatusEnum.pending;
        default:
          return InvoiceStatusEnum.failed;
      }
    } else {
      switch (normalizedStatus) {
        case 'dsa retrieval':
        case 'success':
          return InvoiceStatusEnum.success;
        default:
          return InvoiceStatusEnum.success;
      }
    }
  }

  String _filterICCD(String iccd) {
    if (iccd.contains("_")) {
      return iccd.substring(iccd.indexOf("_") + 1);
    } else {
      return iccd;
    }
  }

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
                      invoiceStatus:
                          _filterInvoiceStatus(invoiceEntity.status, invoiceEntity.msisdn),
                    ),
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
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
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
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
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
                                  : _filterICCD(invoiceEntity.iccid.toString()),
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    _filterInvoiceStatus(invoiceEntity.status, invoiceEntity.msisdn) ==
                            InvoiceStatusEnum.pending
                        ? RetryActivationWidget(invoiceEntity: invoiceEntity)
                        : const SizedBox.shrink()
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
