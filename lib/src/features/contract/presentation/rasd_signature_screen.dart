import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/permissions_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_strings.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/signature_screen.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../../../dependency_injection/injection_container.dart' as di;

class RasdSignatureScreen extends StatefulWidget {
  const RasdSignatureScreen({super.key});

  @override
  State<RasdSignatureScreen> createState() => _RasdSignatureScreenState();
}

class _RasdSignatureScreenState extends State<RasdSignatureScreen> {
  bool _isConditionOfSignatureChecked = false;
  static const platform = MethodChannel('sms/sms_receiver');

  String _smsMessage = "No message received yet.";
  String senderPhoneNumber =
      di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.msisdn!;

  String? signatureImagePath;
  bool isSignatureValidated = false;

  late File signatureFile;

  String currentDateAr = DateFormat('dd-MM-yyyy').format(DateTime.now());
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "signature".tr(context)),
      body: SingleChildScrollView(
        child: Container(
          width: context.width,
          padding: EdgeInsets.all(32.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const ConditionsOfUse(
                    desc: AppStrings.arabicAgrement,
                  ),
                  SizedBox(height: 12.sp),
                  Text(
                    "الجزائر، في $currentDateAr\nأنا، الممضي أسفله، أؤكد أنني قرأت و وافقت على كامل شروط البيع العامة",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 32.h),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: AppColors.secondary),
                    ),
                    height: 200.h,
                    width: 300.w,
                    child: SfSignaturePad(
                      key: _signaturePadKey,
                      minimumStrokeWidth: 5,
                      maximumStrokeWidth: 6,
                      strokeColor: Colors.black,
                      backgroundColor: Colors.white,
                      onDrawStart: () {
                        setState(() {
                          isSignatureValidated = true;
                        });
                        return false;
                      },
                    ),
                  ),
                  EraseSignatureButton(
                    onPressed: () {
                      setState(() {
                        isSignatureValidated = false;
                      });
                      _signaturePadKey.currentState!.clear();
                    },
                  ),
                  SizedBox(height: 24.sp),
                  CheckboxListTile(
                    title: Text(
                      "أوافق على إدراج توقيعي في العقد الخاص بي و كذلك في وثيقة الشروط العامة للبيع",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: _isConditionOfSignatureChecked,
                    onChanged: (value) {
                      setState(() {
                        _isConditionOfSignatureChecked = true;
                      });
                    },
                  ),
                  // SizedBox(height: 24.sp),
                ],
              ),
              SizedBox(height: 64.h),
              ElevatedButton(
                child: Text("confrim_sell".tr(context)),
                onPressed: () async {
                  bool hasPermission = await _requestSmsPermission();
                  if (!hasPermission) {
                    // ignore: use_build_context_synchronously
                    _showPermissionDeniedDialog(context);
                    return;
                  }

                  if (!isSignatureValidated) {
                    AppToasts.showErrorToast(
                      // ignore: use_build_context_synchronously
                      message: "required_signature".tr(context),
                      // ignore: use_build_context_synchronously
                      context: context,
                    );
                    return;
                  }

                  if (!_isConditionOfSignatureChecked) {
                    AppToasts.showErrorToast(
                      // ignore: use_build_context_synchronously
                      message: "signature_approve".tr(context),
                      // ignore: use_build_context_synchronously
                      context: context,
                    );
                    return;
                  }
                  // _checkPermissionsAndShowDialog(context, cubit);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _requestSmsPermission() async {
    PermissionStatus status = await PermissionsUtil.checkPermissionStatus(Permission.sms);
    if (status.isDenied || status.isRestricted) {
      return await PermissionsUtil.requestPermission(Permission.sms);
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return status.isGranted;
  }

  Future<void> _showPermissionDeniedDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('camera_permission_title'.tr(context)),
          content: Text('phone_and_sms_permission_instruction'.tr(context)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                openAppSettings();
              },
              child: Text('open_settings'.tr(context)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('discard'.tr(context)),
            ),
          ],
        );
      },
    );
  }
}
