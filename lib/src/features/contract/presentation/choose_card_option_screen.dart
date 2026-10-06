import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/rasd_ocr_screen.dart';
import 'package:mobilis_smart_pos/src/services/native_ocr.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_elevated_button_text.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/permissions_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';

class ChooseCardOptionScreen extends StatefulWidget {
  const ChooseCardOptionScreen({super.key});

  @override
  State<ChooseCardOptionScreen> createState() => _ChooseCardOptionScreenState();
}

class _ChooseCardOptionScreenState extends State<ChooseCardOptionScreen> {
  late String documentNumber;
  late String dateOfBirth;
  late String dateOfExpiry;
  late String docType;

  String nationality = 'DZ';
  List<String> nationalitiesValues = ['DZ', 'RASD'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> startOCR({required String docType}) async {
    final result = await NativeOCR.startOCR(docType: docType);
    debugPrint("========== RESULT : $result");

    if (result != null) {
      debugPrint("================= DOCUMENT NUMBER : ${result['documentNumber']}");
      debugPrint("================= BIRTH DATE : ${result['birthDate']}");
      debugPrint("================= EXPIRY DATE : ${result['expiredDate']}");
      setState(() {
        documentNumber = result['documentNumber']!;
        dateOfBirth = result['birthDate']!;
        dateOfExpiry = result['expiredDate']!;
      });

      Navigator.of(context).pushNamed(Routes.mrzDetails, arguments: {
        'documentNumber': documentNumber,
        'dateOfBirth': dateOfBirth,
        'dateOfExpiry': dateOfExpiry,
        'docType': docType,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            backgroundColor: context.isDarkMode ? AppColors.darkGrey : Colors.white,
            actions: [
              Container(
                padding: EdgeInsets.all(12.sp),
                width: context.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      "nationality_with_point".tr(context),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(width: 30.sp),
                    DropdownButton<String>(
                      value: nationalitiesValues.contains(nationality) ? nationality : null,
                      items: [
                        // Existing nationalities
                        ...nationalitiesValues.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value == 'DZ' ? 'dz_client'.tr(context) : 'rasd_client'.tr(context),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          );
                        }).toList(),
                        // Add the "Coming Soon" option
                        DropdownMenuItem<String>(
                          value: null, // Set value to null to make it unselectable
                          enabled: false, // Disable the option
                          child: Text(
                            'coming_soon'.tr(context),
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                  color: Colors.grey, // Grey out the text to indicate it's disabled
                                ),
                          ),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            nationality = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                height: context.height - 80.sp,
                width: context.width,
                padding: EdgeInsets.all(20.sp),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "chooseCard".tr(context),
                      style:
                          Theme.of(context).textTheme.bodyLarge!.copyWith(color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                    Lottie.asset(AppImages.chooseScanAnimation, height: 320.h, width: 320.w),
                    SizedBox(height: 32.h),
                    nationality == 'RASD'
                        ? Column(
                            children: [
                              AppElevatedButtonWithText(
                                text: "identityCard".tr(context),
                                onPressed: () async {
                                  bool hasPermission = await _requestCameraPermission();
                                  if (hasPermission) {
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) {
                                        return const RasdOcrScreen();
                                      },
                                    ));
                                  } else {
                                    // ignore: use_build_context_synchronously
                                    await _showPermissionDeniedDialog(context);
                                  }
                                },
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              AppElevatedButtonWithText(
                                text: "identityCard".tr(context),
                                onPressed: () async {
                                  bool hasPermission = await _requestCameraPermission();
                                  if (hasPermission) {
                                    setState(() {
                                      docType = "id_card";
                                    });
                                    await startOCR(docType: "id_card");
                                  } else {
                                    await _showPermissionDeniedDialog(context);
                                  }
                                },
                              ),
                              SizedBox(height: 16.h),
                              AppElevatedButtonWithText(
                                text: "passport".tr(context),
                                onPressed: () async {
                                  bool hasPermission = await _requestCameraPermission();
                                  if (hasPermission) {
                                    setState(() {
                                      docType = "passport";
                                    });
                                    await startOCR(docType: "passport");
                                  } else {
                                    await _showPermissionDeniedDialog(context);
                                  }
                                },
                              ),
                            ],
                          )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('camera_permission_title'.tr(context)),
          content: Text('camera_permission_instruction'.tr(context)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('discard'.tr(context)),
            ),
            TextButton(
              onPressed: () async {
                await PermissionsUtil.openAppSettings();
              },
              child: Text('open_settings'.tr(context)),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _requestCameraPermission() async {
    PermissionStatus status = await PermissionsUtil.checkPermissionStatus(Permission.camera);
    if (status.isDenied || status.isRestricted) {
      return await PermissionsUtil.requestPermission(Permission.camera);
    } else if (status.isPermanentlyDenied) {
      return false;
    }
    return status.isGranted;
  }
}
