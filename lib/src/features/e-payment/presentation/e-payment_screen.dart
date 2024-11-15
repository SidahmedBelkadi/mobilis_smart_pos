import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/commom/widgets/app_text_form_field.dart';
import '../../../core/utils/enums/input_type.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/ressources/app_colors.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          child: Container(
            height: context.height,
            padding: EdgeInsets.all(24.sp),
            child: Column(
              children: [
                Note(
                  note: "noteSimCard".tr(context),
                ),
                SizedBox(height: 64.h),
                AppTextFormField(
                  label: "msisdnLabel".tr(context),
                  prefixText: "🇩🇿 (06)  ",
                  validationType: InputType.PHONE,
                  keyboardType: TextInputType.phone,
                  suffixIcon: Icons.phone_android,
                  textEditingController: TextEditingController(),
                ),
                SizedBox(height: 16.h),
                AppTextFormField(
                  label: "amountLabel".tr(context),
                  keyboardType: TextInputType.number,
                  textEditingController: TextEditingController(),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
                  ),
                  onPressed: () {},
                  child: Text(
                    "validateButton".tr(context),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      foregroundColor: Colors.black,
      backgroundColor: AppColors.secondary,
      centerTitle: true,
      title: Text(
        "paymentTitle".tr(context),
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class Note extends StatelessWidget {
  const Note({
    super.key,
    required this.note,
  });

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 16.sp),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.all(
          Radius.circular(12.sp),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "note".tr(context),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
          ),
          SizedBox(width: 5.sp),
          Flexible(
            child: Text(
              note,
            ),
          ),
        ],
      ),
    );
  }
}
