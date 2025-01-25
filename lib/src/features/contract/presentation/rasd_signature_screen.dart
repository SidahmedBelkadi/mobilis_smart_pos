import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:json_pretty/json_pretty.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/permissions_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_images.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_strings.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/rasd/rasd_contract_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/rasd/rasd_sms_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/signature_screen.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../../../dependency_injection/injection_container.dart' as di;

class RasdSignatureScreen extends StatefulWidget {
  const RasdSignatureScreen({
    super.key,
    required this.rasdParams,
    required this.recto,
    required this.verso,
  });

  final RasdEditRequestParamsEntity rasdParams;
  final File? recto;
  final File? verso;

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

  Timer? _smsTimer;

  late RasdGenerateContractParamsEntity generateContractParamsEntity;
  final String msisdnApn =
      di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.msisdn!;

  int? subscriptiondId;

  @override
  void initState() {
    smsLoading = false;
    platform.setMethodCallHandler((call) async {
      if (call.method == "receivedSms") {
        _smsTimer?.cancel();
        debugPrint("=================== TIMER FOR SMS STOPPED");

        setState(() {
          smsLoading = false;
          _smsMessage = call.arguments;
          checkSmsSuccess(_smsMessage, context);
        });
      }
    });
    super.initState();

    debugPrint(
        "============= RASD CONTRACT SIGNATURE : \n ${prettyPrintJson(jsonEncode(widget.rasdParams.toJson()))}");

    debugPrint("ID CARD RECTO IMAGE SIGNATURE : ${widget.recto?.path}");
    debugPrint("ID CARD VERSO IMAGE SIGNATURE : ${widget.verso?.path}");
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RasdContractCubit>();

    return Scaffold(
      appBar: CustomAppBar(title: "signature".tr(context)),
      body: SingleChildScrollView(
        child: BlocConsumer<RasdSmsCubit, RasdSmsState>(
          listener: (context, state) {
            if (state is RasdTriggerSmsFailed) {
              setState(() {
                smsLoading = false;
              });
              AppToasts.showWarningToast(
                  message: "activation_failed".tr(context), context: context);
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(Routes.main, (route) => false, arguments: {
                "index": 1,
              });
            }
          },
          builder: (context, state) {
            return BlocConsumer<RasdContractCubit, RasdContractState>(
              listener: (context, state) {
                if (state is RasdEditContractFailed) {
                  AppToasts.showErrorToast(message: state.message.tr(context), context: context);
                  Navigator.of(context).pop();
                }
                if (state is RasdGenerateContractFailed) {
                  AppToasts.showErrorToast(message: state.message.tr(context), context: context);
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      Routes.main, arguments: {'index': 1}, (route) => false);
                }
                if (state is RasdGenerateContractSuccess) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(Routes.contractGenerated, (route) => false);
                }

                if (state is RasdGenerateContractSuccess) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(Routes.contractGenerated, (route) => false);
                }

                if (state is RasdEditContractSuccess) {
                  final response = state.rasdEditContractResponseEntity;
                  setState(() {
                    subscriptiondId = response.subscriptionID;
                    generateContractParamsEntity = RasdGenerateContractParamsEntity(
                      contractCode: response.contractCode,
                      dsaMessage: dsaMessage,
                    );
                  });
                  debugPrint("================ STATE IS SUCCESS ==============================  ");
                  final rasdTriggerSmsParamsEntity = RasdTriggerSmsParamsEntity(
                    subscritpionId: response.subscriptionID,
                    msisdnAPN: msisdnApn,
                  );
                  context
                      .read<RasdSmsCubit>()
                      .rasdTriggerSms(rasdTriggerSmsParamsEntity: rasdTriggerSmsParamsEntity);
                  setState(() {
                    smsLoading = true;
                  });
                  _startSmsTimer();
                }
              },
              builder: (context, state) {
                if (state is RasdEditContractLoading) {
                  return SizedBox(
                    height: context.height - 100.h,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 32.sp,
                            width: 32.sp,
                            child: const CircularProgressIndicator(),
                          ),
                          SizedBox(height: 16.sp),
                          Text(
                            "generating".tr(context),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is RasdGenerateContractLoading) {
                  return SizedBox(
                    height: context.height,
                    child: Center(
                      child: SizedBox(
                        height: 32.sp,
                        width: 32.sp,
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  );
                }
                return smsLoading
                    ? SizedBox(
                        height: context.height - 200.h,
                        width: context.width,
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                "please_wait".tr(context),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              SizedBox(height: 12.sp),
                              LottieBuilder.asset(
                                AppImages.smsAnim1,
                                height: 350.sp,
                                width: 350.sp,
                              )
                            ],
                          ),
                        ),
                      )
                    : Container(
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
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: AppColors.primary, fontWeight: FontWeight.bold),
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
                                _checkPermissionsAndShowDialog(context, cubit);
                              },
                            ),
                          ],
                        ),
                      );
              },
            );
          },
        ),
      ),
    );
  }

  _startSmsTimer() {
    _smsTimer = Timer(const Duration(seconds: 30), () {
      AppToasts.showWarningToast(message: "activation_failed".tr(context), context: context);
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
    });
  }

  void checkSmsSuccess(String message, BuildContext context) {
    debugPrint("==================== MESSAGE : $message");
    setState(() {
      generateContractParamsEntity.dsaMessage = message;
    });

    final RegExp regExp = RegExp(r'La carte SIM (\d+) est activee, avec le numero (2136\d{8})');
    final RegExp regExp2 = RegExp(r'Activation en cours');
    final match = regExp.firstMatch(message);
    final cubit = context.read<RasdContractCubit>();

    if (match != null) {
      final phoneNumber = match.group(2);

      if (phoneNumber != null) {
        generateContractParamsEntity.msisdn = phoneNumber;

        cubit.rasdGenerateContract(
            params: generateContractParamsEntity, subscriptionId: subscriptiondId!);
      }
    } else {
      debugPrint("===================== Message: $message");
      if (!regExp2.hasMatch(message)) {
        generateContractParamsEntity.msisdn = "FAILED";

        cubit.rasdGenerateContract(
            params: generateContractParamsEntity, subscriptionId: subscriptiondId!);
      } else if (regExp2.hasMatch(message)) {
      } else {
        AppToasts.showErrorToast(message: message, context: context);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _checkPermissionsAndShowDialog(BuildContext context, RasdContractCubit cubit) async {
    final smsStatus = await Permission.sms.request();
    final phoneStatus = await Permission.phone.request();

    if (smsStatus.isGranted && phoneStatus.isGranted) {
      // ignore: use_build_context_synchronously
      _showConfirmationDialog(context, cubit);
    } else {
      // ignore: use_build_context_synchronously
      _showPermissionDeniedDialog(context);
    }
  }

  Future<void> _showConfirmationDialog(BuildContext context, RasdContractCubit cubit) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "activation_instruction".tr(context),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("discard".tr(context)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'accept'.tr(context),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final file = await _saveSignature();
                setState(() {
                  signatureFile = file;
                });

                cubit.rasdEditContract(
                  params: widget.rasdParams,
                  recto: widget.recto,
                  verso: widget.verso,
                  signature: signatureFile,
                );
                debugPrint("============ REQUESTED ============");
              },
            ),
          ],
        );
      },
    );
  }

  Future<File> _saveSignature() async {
    final ui.Image image = await _signaturePadKey.currentState!.toImage();
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imageData = byteData!.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/signature.png').create();
    await file.writeAsBytes(imageData);
    setState(() {
      signatureImagePath = file.path;
    });
    return file;
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
