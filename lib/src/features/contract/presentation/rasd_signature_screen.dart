import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_images.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_trigger_sms_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/rasd/rasd_contract_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/rasd/rasd_sms_cubit.dart';
import 'package:pdfx/pdfx.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import 'package:mobilis_smart_pos/src/services/screenshot_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import '../../../dependency_injection/injection_container.dart' as di;
import 'cubit/cgv_cubit.dart';

class RasdSignatureScreen extends StatefulWidget {
  const RasdSignatureScreen({
    super.key,
    required this.rasdParams,
    required this.recto,
    required this.verso,
    this.offerName,
  });

  final RasdEditRequestParamsEntity rasdParams;
  final File? recto;
  final File? verso;
  final String? offerName;

  @override
  State<RasdSignatureScreen> createState() => _RasdSignatureScreenState();
}

bool smsLoading = false;
String dsaMessage = '';

class _RasdSignatureScreenState extends State<RasdSignatureScreen> {
  static const platform = MethodChannel('sms/sms_receiver');

  String _smsMessage = "No message received yet.";
  String senderPhoneNumber =
      di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.msisdn!;

  String? signatureImagePath;
  bool isSignatureValidated = false;

  late File signatureFile;

  Timer? _smsTimer;
  bool _isContractGenerationTriggered = false;

  late RasdGenerateContractParamsEntity generateContractParamsEntity;
  final String msisdnApn =
      di.serviceLocator<SmartPosLocalStorage>().getSavedLoginCredentials()!.msisdn!;

  int? subscriptiondId;
  PdfControllerPinch? pdfControllerPinch;
  bool _errorLoadingPdf = false;

  Future<void> _loadPdf(Uint8List pdfBytes) async {
    try {
      if (pdfBytes.isEmpty) throw Exception("Empty PDF data");

      final document = await PdfDocument.openData(pdfBytes);
      if (mounted) {
        setState(() {
          pdfControllerPinch = PdfControllerPinch(document: Future.value(document));
          _errorLoadingPdf = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorLoadingPdf = true;
        });
      }
    }
  }

  @override
  void initState() {
    ScreenshotService.preventScreenshotOn();
    smsLoading = false;
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final offerName = widget.offerName ?? 'SAMA';
        context
            .read<CgvCubit>()
            .getDynamicCGV(offerName: offerName, lang: context.isArabicLocale ? 'AR' : 'FR');
      }
    });

    platform.setMethodCallHandler((call) async {
      if (call.method == "receivedSms") {
        _smsTimer?.cancel();
        debugPrint("=================== TIMER FOR SMS STOPPED");

        setState(() {
          _smsMessage = call.arguments;
          checkSmsSuccess(_smsMessage, context);
        });
      }
    });
  }

  @override
  void dispose() {
    _smsTimer?.cancel();
    ScreenshotService.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RasdContractCubit>();

    return SessionTimeout(
      child: Scaffold(
        appBar: CustomAppBar(title: "signature".tr(context)),
        body: SafeArea(
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
                    return const ProcessingContractLoading();
                  }

                  if (state is RasdGenerateContractLoading) {
                    return const ProcessingContractLoading();
                  }
                  return smsLoading
                      ? const SendingActivationSMS()
                      : BlocConsumer<CgvCubit, CgvState>(
                          listener: (context, cgvState) {
                            if (cgvState is LoadCGVSucceded) {
                              _loadPdf(cgvState.pdfBytes);
                            }
                            if (cgvState is LoadCGVFailed) {
                              AppToasts.showErrorToast(
                                  message: "CGV_indisponibles".tr(context), context: context);
                              Navigator.of(context).pop();
                            }
                          },
                          builder: (context, cgvState) {
                            if (cgvState is LoadCGVLoading) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (cgvState is LoadCGVSucceded) {
                              if (pdfControllerPinch == null && !_errorLoadingPdf) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final mediaQuery = MediaQuery.of(context);
                              final appBarHeight = AppBar().preferredSize.height;
                              final bottomNavHeight = 56.h;
                              final availableHeight = mediaQuery.size.height -
                                  mediaQuery.padding.top -
                                  appBarHeight -
                                  bottomNavHeight;
                              return SizedBox(
                                height: availableHeight,
                                width: mediaQuery.size.width,
                                child: PdfViewPinch(controller: pdfControllerPinch!),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                },
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 56.h,
            width: double.infinity,
            padding: EdgeInsets.only(left: 16.sp, right: 16.sp, bottom: 8.sp, top: 8.sp),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BlocBuilder<CgvCubit, CgvState>(
              builder: (context, cgvState) {
                final isPdfDisplayed =
                    cgvState is LoadCGVSucceded && pdfControllerPinch != null && !_errorLoadingPdf;
  
                if (!isPdfDisplayed || smsLoading) {
                  return const SizedBox.shrink();
                }
  
                return ElevatedButton(
                  onPressed: () => _showSignatureModal(context, cubit),
                  child: Text("signature".tr(context)),
                );
              },
            ),
          ),
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

    final RegExp regExp2 = RegExp(r'Activation en cours');
    if (regExp2.hasMatch(message)) {
      return;
    }

    if (_isContractGenerationTriggered) {
      return;
    }

    setState(() {
      generateContractParamsEntity.dsaMessage = message;
    });

    final RegExp regExp = RegExp(r'La carte SIM (\d+) est activee, avec le numero (2136\d{8})');
    final match = regExp.firstMatch(message);
    final cubit = context.read<RasdContractCubit>();

    if (match != null) {
      final phoneNumber = match.group(2);
      final dsaICCID = match.group(1);
      final iccid = "892130${widget.rasdParams.serialNumber}";
      debugPrint("=================== COMPOSED ICCID : $iccid ");
      if (phoneNumber != null && iccid == dsaICCID) {
        generateContractParamsEntity.msisdn = phoneNumber;
        _isContractGenerationTriggered = true;
        cubit.rasdGenerateContract(
            params: generateContractParamsEntity, subscriptionId: subscriptiondId!);
      }
    } else {
      debugPrint("===================== Message: $message");
      generateContractParamsEntity.msisdn = "FAILED";
      _isContractGenerationTriggered = true;
      cubit.rasdGenerateContract(
          params: generateContractParamsEntity, subscriptionId: subscriptiondId!);
    }
  }

  Future<bool> _checkPermissionsAndActivate(
      BuildContext context, RasdContractCubit cubit, File signature) async {
    final smsStatus = await Permission.sms.request();

    if (smsStatus.isGranted) {
      cubit.rasdEditContract(
        params: widget.rasdParams,
        recto: widget.recto,
        verso: widget.verso,
        signature: signature,
      );
      debugPrint("============ REQUESTED ============");
      return true;
    } else {
      if (!mounted) return false;
      await _showPermissionDeniedDialog(context);
      return false;
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

  Future<void> _showSignatureModal(BuildContext context, RasdContractCubit cubit) {
    final GlobalKey<SfSignaturePadState> modalSignaturePadKey = GlobalKey();
    bool modalSignatureValidated = false;
    bool modalConditionChecked = false;
    bool isSubmitting = false;

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
                          child: const Icon(Icons.clear),
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
                              if (isSubmitting) return;
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

                              final ui.Image image =
                                  await modalSignaturePadKey.currentState!.toImage();
                              final ByteData? byteData =
                                  await image.toByteData(format: ui.ImageByteFormat.png);
                              final Uint8List imageData = byteData!.buffer.asUint8List();
                              final tempDir = await getTemporaryDirectory();
                              final file = await File('${tempDir.path}/signature.png').create();
                              await file.writeAsBytes(imageData);

                              setModalState(() {
                                isSubmitting = true;
                              });
                              setState(() {
                                signatureFile = file;
                                signatureImagePath = file.path;
                                isSignatureValidated = true;
                              });

                              final didTriggerActivation =
                                  await _checkPermissionsAndActivate(context, cubit, file);
                              if (didTriggerActivation && mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                              if (mounted) {
                                setModalState(() {
                                  isSubmitting = false;
                                });
                              }
                            },
                            child: isSubmitting
                                ? SizedBox(
                                    height: 16.sp,
                                    width: 16.sp,
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text("confirm".tr(context)),
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
}

class SendingActivationSMS extends StatelessWidget {
  const SendingActivationSMS({super.key});

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
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessingContractLoading extends StatelessWidget {
  const ProcessingContractLoading({super.key});

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
