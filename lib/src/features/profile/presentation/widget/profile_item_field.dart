import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/commom/widgets/app_text_form_field.dart';

class ProfileItem extends StatefulWidget {
  const ProfileItem({
    super.key,
    required this.label,
    required this.value,
    this.obsecureOption = false,
    this.isFilled = true,
  });

  final String label;
  final String value;
  final bool obsecureOption;
  final bool isFilled;

  @override
  State<ProfileItem> createState() => _ProfileItemState();
}

class _ProfileItemState extends State<ProfileItem> {
  bool isObsecure = true; // Initial state should be true for obscured text

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        SizedBox(height: 5.sp),
        AppTextFormField(
          isObsecure: widget.obsecureOption ? isObsecure : false,
          readOnly: true,
          filled: widget.isFilled,
          onSuffixTap: widget.obsecureOption
              ? () {
                  setState(() {
                    isObsecure = !isObsecure;
                  });
                }
              : null,
          suffixIcon: widget.obsecureOption
              ? isObsecure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined
              : null,
          textEditingController: TextEditingController.fromValue(
            TextEditingValue(text: widget.value),
          ),
        ),
      ],
    );
  }
}
