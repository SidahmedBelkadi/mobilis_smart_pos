import 'package:flutter/material.dart';

import '../ressources/app_colors.dart';

class InvoiceStatusEnum {
  final String name;
  final Color color;
  final Color backgroundColor;

  const InvoiceStatusEnum._(this.name, this.color, this.backgroundColor);

  static InvoiceStatusEnum success = InvoiceStatusEnum._(
    "success",
    AppColors.inProgressTextColor,
    AppColors.secondaryLight,
  );

  static const InvoiceStatusEnum failed = InvoiceStatusEnum._(
    "failed",
    AppColors.waitingTextColor,
    AppColors.waittingBackgroundColor,
  );

  static const InvoiceStatusEnum pending = InvoiceStatusEnum._(
    "pending",
    AppColors.white,
    Colors.amber,
  );

  static const InvoiceStatusEnum skeleton = InvoiceStatusEnum._(
    "skeleton",
    Colors.black,
    AppColors.darkerGrey,
  );

  static List<InvoiceStatusEnum> values = [success, failed, pending, skeleton];
}
