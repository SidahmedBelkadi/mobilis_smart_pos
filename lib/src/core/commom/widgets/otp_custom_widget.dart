import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/app.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pinput/pinput.dart';

import '../../utils/helpers/media_query_values.dart';
import '../../utils/ressources/app_colors.dart';

class OTPCustomWidget extends StatefulWidget {
  const OTPCustomWidget({
    super.key,
    this.onCompleted,
    this.controller,
  });

  final void Function(String)? onCompleted;
  final TextEditingController? controller;

  @override
  State<OTPCustomWidget> createState() => _OTPCustomWidgetState();
}

class _OTPCustomWidgetState extends State<OTPCustomWidget> with WidgetsBindingObserver {
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Permission.sms.status.then((status) {
        if (status.isGranted) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.signIn, (context) => false);
        }
      });
    }
  }

  Future<void> _checkPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final status = await Permission.sms.status;
    setState(() {
      _hasPermission = status.isGranted;
      _isCheckingPermission = false;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.sms.status;

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      return;
    }

    final result = await Permission.sms.request();

    if (result.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (result.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("permission_required".tr(context)),
          content: Text("please_enable_sms_permission".tr(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("cancel".tr(context)),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: Text("open_settings".tr(context)),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusedBorderColor = AppColors.primary;
    final fillColor = context.isDarkMode ? Colors.black : const Color.fromRGBO(243, 246, 249, 0);
    final borderColor = AppColors.secondary;

    final defaultPinTheme = PinTheme(
      width: 60.sp,
      height: 60.sp,
      textStyle: TextStyle(
        fontSize: 16.sp,
        color: context.isDarkMode ? AppColors.primary : const Color.fromRGBO(30, 60, 87, 1),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(19.sp),
        border: Border.all(color: borderColor),
      ),
    );

    final shouldShowWarning = !_hasPermission && !_isCheckingPermission;

    return Column(
      children: [
        if (shouldShowWarning) _buildPermissionWarning(context),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            controller: widget.controller,
            length: 6,
            obscureText: false,
            autofocus: false,
            readOnly: true, // User cannot type manually
            validator: (value) {
              if (value == null || value.isEmpty) return '';
              if (value.length != 6) return '';
              if (!RegExp(r'^\d+$').hasMatch(value)) return '';
              return null;
            },
            hapticFeedbackType: HapticFeedbackType.heavyImpact,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: focusedBorderColor, width: 2),
              ),
            ),
            submittedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                color: fillColor,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: focusedBorderColor, width: 2),
              ),
            ),
            errorPinTheme: defaultPinTheme.copyBorderWith(
              border: Border.all(color: Colors.redAccent),
            ),
            followingPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                color: fillColor,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: focusedBorderColor, width: 2),
              ),
            ),
            onCompleted: widget.onCompleted,
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionWarning(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      margin: EdgeInsets.only(bottom: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber),
          SizedBox(width: 8.sp),
          Expanded(
            child: Text(
              "auto_otp_warning".tr(context),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: _requestPermission,
            child: Text(
              "grant".tr(context),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
