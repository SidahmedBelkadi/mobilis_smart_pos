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
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_strings.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_generate_contract_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/rasd_request_params_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/rasd/rasd_contract_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/signature_screen.dart';
import 'package:mobilis_smart_pos/src/services/screenshot_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

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
  String? signatureImagePath;
  bool isSignatureValidated = false;
  late File signatureFile;
  String currentDateAr = DateFormat('dd-MM-yyyy').format(DateTime.now());
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();

  late RasdGenerateContractParamsEntity generateContractParamsEntity;

  bool isEditContractLoading = false;

  @override
  void initState() {
    ScreenshotService.preventScreenshotOn();
    super.initState();

    debugPrint(
        "============= RASD CONTRACT SIGNATURE : \n ${prettyPrintJson(jsonEncode(widget.rasdParams.toJson()))}");

    debugPrint("ID CARD RECTO IMAGE SIGNATURE : ${widget.recto?.path}");
    debugPrint("ID CARD VERSO IMAGE SIGNATURE : ${widget.verso?.path}");
  }

  @override
  void dispose() {
    ScreenshotService.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RasdContractCubit>();

    return SessionTimeout(
      child: Scaffold(
        appBar: CustomAppBar(title: "signature".tr(context)),
        body: SingleChildScrollView(
          child: BlocConsumer<RasdContractCubit, RasdContractState>(
            listener: (context, state) {
              if (state is RasdEditContractFailed) {
                setState(() {
                  isEditContractLoading = false;
                });
                AppToasts.showErrorToast(message: state.message.tr(context), context: context);
                Navigator.of(context).pop();
              }

              if (state is RasdEditContractSuccess) {
                setState(() {
                  isEditContractLoading = false;
                });

                Navigator.of(context)
                    .pushNamedAndRemoveUntil(Routes.contractGenerated, (route) => false);
              }
            },
            builder: (context, state) {
              if (isEditContractLoading) {
                return EditContractLoadingWidget();
              }
              return Container(
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
                        _showConfirmationDialog(context, cubit);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
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

                setState(() {
                  isEditContractLoading = true;
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
}

class EditContractLoadingWidget extends StatelessWidget {
  const EditContractLoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
}
