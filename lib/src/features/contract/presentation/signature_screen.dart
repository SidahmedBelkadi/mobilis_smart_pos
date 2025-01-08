import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/permissions_helper.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/sms_cubit.dart';
import '../../../core/commom/widgets/custom_app_bar.dart';
import '../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../../services/screenshot_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readmore/readmore.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../../../core/utils/ressources/app_strings.dart';
import '../../../dependency_injection/injection_container.dart' as di;
import '../domain/entities/contract_request_params_entitiy.dart';
import '../domain/entities/generate_contract_params_entity.dart';
import 'cubit/contract_cubit.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({
    super.key,
    required this.formattedSmsCode,
    required this.contract,
    this.recto,
    this.verso,
    required this.isPassport,
    this.parentRecto,
    this.parentVerso,
    this.justificatif,
    this.parentIsPassport,
  });

  final String formattedSmsCode;
  final ContractRequestParamsEntitiy contract;
  final File? recto;
  final File? verso;
  final bool isPassport;
  final File? parentRecto;
  final File? parentVerso;
  final File? justificatif;
  final bool? parentIsPassport;

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

bool smsLoading = false;
String dsaMessage = '';

late GenerateContractParamsEntity generateContractParamsEntity;

GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

class _SignatureScreenState extends State<SignatureScreen> {
  bool _isConditionOfSignatureChecked = false;
  static const platform = MethodChannel('sms/sms_receiver');

  String _smsMessage = "No message received yet.";
  String senderPhoneNumber =
      di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.msisdn!;

  String? signatureImagePath;
  bool isSignatureValidated = false;

  late File signatureFile;

  String currentDateAr = DateFormat('dd-MM-yyyy').format(DateTime.now());
  Timer? _smsTimer;

  @override
  void initState() {
    smsLoading = false;
    super.initState();
    ScreenshotService.disableScreenshots();

    platform.setMethodCallHandler((call) async {
      if (call.method == "receivedSms") {
        // Cancel the timer when SMS is received
        _smsTimer?.cancel();
        debugPrint("=================== TIMER FOR SMS STOPPED");

        setState(() {
          smsLoading = false;
          _smsMessage = call.arguments;
          checkSmsSuccess(_smsMessage, context);
        });
      }
    });
  }

  @override
  void dispose() {
    _smsTimer?.cancel();
    super.dispose();
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
    final cubit = context.read<ContractCubit>();

    if (match != null) {
      final phoneNumber = match.group(2);

      if (phoneNumber != null) {
        generateContractParamsEntity.msisdn = phoneNumber;
        cubit.attributeMsisdnAndGenerateContract(params: generateContractParamsEntity);
      }
    } else {
      debugPrint("===================== Message: $message");
      if (!regExp2.hasMatch(message)) {
        generateContractParamsEntity.msisdn = "FAILED";
        cubit.attributeMsisdnAndGenerateContract(params: generateContractParamsEntity);
      } else if (regExp2.hasMatch(message)) {
      } else {
        AppToasts.showErrorToast(message: message, context: context);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _checkPermissionsAndShowDialog(BuildContext context, ContractCubit cubit) async {
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

  Future<void> _showConfirmationDialog(BuildContext context, ContractCubit cubit) {
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

                // Make the API call first
                cubit.editContract(
                    contract: widget.contract,
                    recto: widget.recto,
                    verso: widget.verso,
                    signature: signatureFile,
                    isPassport: widget.isPassport,
                    parentRecto: widget.parentRecto,
                    parentVerso: widget.parentVerso,
                    justifiatif: widget.justificatif,
                    parentIsPassport: widget.parentIsPassport);
                ScreenshotService.enableScreenshots();
                debugPrint("============ REQUESTED ============");
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ContractCubit>();
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppBar(title: "signature".tr(context)),
        body: SingleChildScrollView(
          child: Container(
            width: context.width,
            padding: EdgeInsets.all(32.sp),
            child: BlocConsumer<SmsCubit, SmsState>(
              listener: (context, state) {
                if (state is TriggerSmsFailure) {
                  setState(() {
                    smsLoading = false;
                  });
                  AppToasts.showWarningToast(
                      message: "activation_failed".tr(context), context: context);
                  Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
                }
              },
              builder: (context, state) {
                return BlocConsumer<ContractCubit, ContractState>(
                  listener: (context, state) {
                    if (state is EditContractFailed) {
                      AppToasts.showErrorToast(
                          message: state.message.tr(context), context: context);
                      Navigator.of(context).pop();
                    }
                    if (state is GenerateContractFailed) {
                      AppToasts.showErrorToast(
                          message: state.message.tr(context), context: context);
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.main,
                          arguments: {'index': 1, 'fromSignin': true},
                          (route) => false);
                    }
                    if (state is GenerateContractSuccess) {
                      Navigator.of(context).pushReplacementNamed(Routes.contractGenerated);
                    }

                    if (state is EditContractSuccess) {
                      final response = state.editContractResponseEntity;
                      setState(() {
                        generateContractParamsEntity = GenerateContractParamsEntity(
                          clientId: response.clientId,
                          invoiceId: response.invoiceId,
                          subsId: response.subscriptionId,
                          contractCode: response.contractCode,
                          dsaMessage: dsaMessage,
                        );
                      });
                      debugPrint(
                          "================ STATE IS SUCCESS ==============================  ");
                      final smsParams = TriggerSmsParamsEntity(
                          id: generateContractParamsEntity.invoiceId,
                          msisdnAPN: senderPhoneNumber,
                          formattedSmsString:
                              '892130${widget.contract.serialNumber}${widget.formattedSmsCode}');
                      context.read<SmsCubit>().triggerSms(smsParams: smsParams);
                      setState(() {
                        smsLoading = true;
                      });
                      _startSmsTimer();
                    }
                  },
                  builder: (context, state) {
                    if (state is EditContractLoading) {
                      return Center(
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
                      );
                    }
                    if (state is GenerateContractLoading) {
                      return SizedBox(
                        height: context.height - 100.sp,
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
                            height: context.height,
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
                        : Column(
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
                                    _showPermissionDeniedDialog(context);
                                    return;
                                  }

                                  if (!isSignatureValidated) {
                                    AppToasts.showErrorToast(
                                      message: "required_signature".tr(context),
                                      context: context,
                                    );
                                    return;
                                  }

                                  if (!_isConditionOfSignatureChecked) {
                                    AppToasts.showErrorToast(
                                      message: "signature_approve".tr(context),
                                      context: context,
                                    );
                                    return;
                                  }
                                  _checkPermissionsAndShowDialog(context, cubit);
                                },
                              ),
                            ],
                          );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class EraseSignatureButton extends StatelessWidget {
  const EraseSignatureButton({
    super.key,
    this.onPressed,
  });

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.clear),
          ],
        ),
      ),
    );
  }
}

class ConditionsOfUse extends StatelessWidget {
  const ConditionsOfUse({
    super.key,
    required this.desc,
  });

  final String desc;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: ReadMoreText(
        desc,
        trimLines: 130,
        trimMode: TrimMode.Line,
        trimCollapsedText: "show_more".tr(context),
        trimExpandedText: "show_less".tr(context),
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: AppColors.secondaryText,
            ),
        moreStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
        lessStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
