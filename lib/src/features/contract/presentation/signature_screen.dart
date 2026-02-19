import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_appbar_with_deny_contract.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/sms_cubit.dart';
import '../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../../services/screenshot_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:readmore/readmore.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
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
  bool _isContractGenerationTriggered = false;

  late PdfController _pdfController;
  bool _isPdfLoaded = false;

  @override
  void initState() {
    smsLoading = false;
    super.initState();
    ScreenshotService.disableScreenshots();

    _pdfController = PdfController(
      document: PdfDocument.openAsset('assets/pdf/cgv_5g_static.pdf'),
    );
    _pdfController.loadingState.addListener(() {
      if (_pdfController.loadingState.value == PdfLoadingState.success) {
        if (mounted) {
          setState(() {
            _isPdfLoaded = true;
          });
        }
      }
    });

    platform.setMethodCallHandler((call) async {
      if (call.method == "receivedSms") {
        // Cancel the timer when SMS is received
        _smsTimer?.cancel();
        debugPrint("=================== TIMER FOR SMS STOPPED");

        setState(() {
          // smsLoading = false;
          _smsMessage = call.arguments;
          checkSmsSuccess(_smsMessage, context);
        });
      }
    });
  }

  @override
  void dispose() {
    _smsTimer?.cancel();
    _pdfController.dispose();
    super.dispose();
  }

  _startSmsTimer() {
    _smsTimer = Timer(const Duration(seconds: 30), () {
      AppToasts.showWarningToast(message: "activation_failed".tr(context), context: context);
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.main, (route) => false);
    });
  }

  void checkSmsSuccess(String message, BuildContext context) {
    debugPrint("==================== MESSAGE : $message");

    // Ignore "Activation en cours" messages completely
    final RegExp regExp2 = RegExp(r'Activation en cours');
    if (regExp2.hasMatch(message)) {
      debugPrint("==================== Ignoring 'Activation en cours' message");
      return;
    }

    // Prevent duplicate calls
    if (_isContractGenerationTriggered) {
      debugPrint(
          "==================== Contract generation already triggered, ignoring duplicate message");
      return;
    }

    setState(() {
      generateContractParamsEntity.dsaMessage = message;
    });

    final RegExp regExp = RegExp(r'La carte SIM (\d+) est activee, avec le numero (2136\d{8})');
    final match = regExp.firstMatch(message);
    final cubit = context.read<ContractCubit>();

    if (match != null) {
      final phoneNumber = match.group(2);
      final dsaICCID = match.group(1);
      final iccid = "892130${widget.contract.serialNumber}";
      debugPrint("=================== COMPOSED ICCID : $iccid ");
      debugPrint("=================== Extraced MSISDN : $phoneNumber");

      if (phoneNumber != null && dsaICCID == iccid) {
        generateContractParamsEntity.msisdn = phoneNumber;
        _isContractGenerationTriggered = true;
        cubit.attributeMsisdnAndGenerateContract(params: generateContractParamsEntity);
      }
    } else {
      debugPrint("===================== Message: $message");
      generateContractParamsEntity.msisdn = "FAILED";
      _isContractGenerationTriggered = true;
      cubit.attributeMsisdnAndGenerateContract(params: generateContractParamsEntity);
    }
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

                // signatureFile is already set by _showSignatureModal
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

  Future<void> _showSignatureModal(BuildContext context) {
    // Create a new signature pad key for the modal
    final GlobalKey<SfSignaturePadState> modalSignaturePadKey = GlobalKey();
    bool modalSignatureValidated = false;
    bool modalConditionChecked = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              child: Container(
                padding: EdgeInsets.all(24.sp),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "signature".tr(context),
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.sp),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: AppColors.secondary),
                        ),
                        height: 200.h,
                        width: double.infinity,
                        child: SfSignaturePad(
                          key: modalSignaturePadKey,
                          minimumStrokeWidth: 5,
                          maximumStrokeWidth: 6,
                          strokeColor: Colors.black,
                          backgroundColor: Colors.white,
                          onDrawStart: () {
                            setModalState(() {
                              modalSignatureValidated = true;
                            });
                            return false;
                          },
                        ),
                      ),
                      SizedBox(height: 12.sp),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setModalState(() {
                              modalSignatureValidated = false;
                            });
                            modalSignaturePadKey.currentState!.clear();
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.clear),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.sp),
                      CheckboxListTile(
                        title: Text(
                          "signature_approve".tr(context),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: modalConditionChecked,
                        onChanged: (value) {
                          setModalState(() {
                            modalConditionChecked = value ?? false;
                          });
                        },
                      ),
                      SizedBox(height: 24.sp),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text("discard".tr(context)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (!modalSignatureValidated) {
                                AppToasts.showErrorToast(
                                  message: "required_signature".tr(context),
                                  context: dialogContext,
                                );
                                return;
                              }

                              if (!modalConditionChecked) {
                                AppToasts.showErrorToast(
                                  message: "signature_approve".tr(context),
                                  context: dialogContext,
                                );
                                return;
                              }

                              // Save the signature
                              final ui.Image image =
                                  await modalSignaturePadKey.currentState!.toImage();
                              final ByteData? byteData =
                                  await image.toByteData(format: ui.ImageByteFormat.png);
                              final Uint8List imageData = byteData!.buffer.asUint8List();
                              final tempDir = await getTemporaryDirectory();
                              final file = await File('${tempDir.path}/signature.png').create();
                              await file.writeAsBytes(imageData);

                              setState(() {
                                signatureFile = file;
                                signatureImagePath = file.path;
                                isSignatureValidated = true;
                                _isConditionOfSignatureChecked = true;
                              });

                              Navigator.of(dialogContext).pop();
                            },
                            child: Text("confirm".tr(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ContractCubit>();
    return SessionTimeout(
      child: PopScope(
        canPop: false,
        child: Scaffold(
          appBar: CustomAppbarWithDenyContract(
            title: "signature".tr(context),
            isActionEnabled: false,
            automaticallyImplyLeading: false,
          ),
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
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.main,
                            arguments: {'index': 1, 'fromSignin': false},
                            (route) => false);
                      }
                      if (state is GenerateContractFailed) {
                        AppToasts.showErrorToast(
                            message: state.message.tr(context), context: context);
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.main,
                            arguments: {'index': 1, 'fromSignin': false},
                            (route) => false);
                      }
                      if (state is GenerateContractSuccess) {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil(Routes.contractGenerated, (route) => false);
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
                        return ProcessingContractLoading();
                      }
                      if (state is GenerateContractLoading) {
                        return ProcessingContractLoading();
                      }
                      return smsLoading
                          ? SendingActivationSMS()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // PDF viewer
                                SizedBox(
                                  height: 550.h,
                                  width: context.width,
                                  child: PdfView(
                                    controller: _pdfController,
                                    scrollDirection: Axis.vertical,
                                    physics: const BouncingScrollPhysics(),
                                    builders: PdfViewBuilders<DefaultBuilderOptions>(
                                      options: const DefaultBuilderOptions(),
                                      documentLoaderBuilder: (_) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      pageLoaderBuilder: (_) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 64.h),

                                if (_isPdfLoaded)
                                  isSignatureValidated && _isConditionOfSignatureChecked
                                      ? ElevatedButton(
                                          child: Text("activate_sim".tr(context)),
                                          onPressed: () async {
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
                                        )
                                      : ElevatedButton(
                                          child: Text("confrim_sell".tr(context)),
                                          onPressed: () async {
                                            // if (!isSignatureValidated) {
                                            //   AppToasts.showErrorToast(
                                            //     message: "required_signature".tr(context),
                                            //     context: context,
                                            //   );
                                            //   return;
                                            // }

                                            // if (!_isConditionOfSignatureChecked) {
                                            //   AppToasts.showErrorToast(
                                            //     message: "signature_approve".tr(context),
                                            //     context: context,
                                            //   );
                                            //   return;
                                            //}
                                            _showSignatureModal(context);
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
      ),
    );
  }
}

class SendingActivationSMS extends StatelessWidget {
  const SendingActivationSMS({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

class ProcessingContractLoading extends StatelessWidget {
  const ProcessingContractLoading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
