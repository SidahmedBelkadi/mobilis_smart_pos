import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/session_timeout.dart';
import '../../../core/commom/widgets/custom_app_bar.dart';
import '../../../services/screenshot_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:readmore/readmore.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_strings.dart';
import '../domain/entities/contract_request_params_entitiy.dart';
import '../domain/entities/generate_contract_params_entity.dart';
import 'cubit/contract_cubit.dart';

class SignatureScreen extends StatefulWidget {
  const SignatureScreen({
    super.key,
    required this.contract,
    this.recto,
    this.verso,
    required this.isPassport,
    this.parentRecto,
    this.parentVerso,
    this.justificatif,
    this.parentIsPassport,
  });

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
  String? signatureImagePath;
  bool isSignatureValidated = false;
  late File signatureFile;

  bool isEditContractLoading = false;
  bool isGenerateContractLoading = false;

  @override
  void initState() {
    smsLoading = false;
    super.initState();
    ScreenshotService.disableScreenshots();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ContractCubit>();
    return SessionTimeout(
      child: SafeArea(
        child: Scaffold(
          appBar: CustomAppBar(title: "signature".tr(context)),
          body: SingleChildScrollView(
            child: Container(
              width: context.width,
              padding: EdgeInsets.all(32.sp),
              child: BlocConsumer<ContractCubit, ContractState>(
                listener: (context, state) {
                  if (state is EditContractFailed) {
                    setState(() {
                      isEditContractLoading = false;
                    });
                    AppToasts.showErrorToast(message: state.message.tr(context), context: context);
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                  if (state is GenerateContractFailed) {
                    setState(() {
                      isGenerateContractLoading = false;
                    });
                    AppToasts.showErrorToast(message: state.message.tr(context), context: context);
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.main, arguments: {'index': 1, 'fromSignin': true}, (route) => false);
                  }
                  if (state is GenerateContractSuccess) {
                    setState(() {
                      isGenerateContractLoading = false;
                    });
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(Routes.contractGenerated, (route) => false);
                  }

                  if (state is EditContractSuccess) {
                    setState(() {
                      isEditContractLoading = false;
                    });
                    final response = state.editContractResponseEntity;
                    setState(() {
                      generateContractParamsEntity = GenerateContractParamsEntity(
                        invoiceId: response.invoiceId,
                        subsId: response.subscriptionId,
                      );

                      isGenerateContractLoading = true;
                    });

                    cubit.generateContract(params: generateContractParamsEntity);
                  }
                },
                builder: (context, state) {
                  if (isEditContractLoading) {
                    return const ContractLoading();
                  }
                  if (isGenerateContractLoading) {
                    return const ContractLoading();
                  }
                  return Body(
                    onDrawStart: () {
                      setState(() {
                        isSignatureValidated = true;
                      });
                      return false;
                    },
                    onErasePressed: () {
                      setState(() {
                        isSignatureValidated = false;
                      });
                      _signaturePadKey.currentState!.clear();
                    },
                    isConditionOfSignatureChecked: _isConditionOfSignatureChecked,
                    onCheckBoxChanged: (value) {
                      setState(() {
                        _isConditionOfSignatureChecked = true;
                      });
                    },
                    isSignatureValidated: isSignatureValidated,
                    showConfirmationDialog: () {
                      _showConfirmationDialog(context, cubit);
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

                setState(() {
                  isEditContractLoading = true;
                });
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
}

class Body extends StatelessWidget {
  const Body({
    super.key,
    this.onDrawStart,
    this.onErasePressed,
    required this.isConditionOfSignatureChecked,
    this.onCheckBoxChanged,
    required this.isSignatureValidated,
    required this.showConfirmationDialog,
  });

  final bool Function()? onDrawStart;
  final void Function()? onErasePressed;
  final void Function(bool?)? onCheckBoxChanged;
  final bool isConditionOfSignatureChecked;
  final bool isSignatureValidated;
  final VoidCallback showConfirmationDialog;

  @override
  Widget build(BuildContext context) {
    String currentDateAr = DateFormat('dd-MM-yyyy').format(DateTime.now());

    return Column(
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
                onDrawStart: onDrawStart,
              ),
            ),
            EraseSignatureButton(
              onPressed: onErasePressed,
            ),
            SizedBox(height: 24.sp),
            CheckboxListTile(
              title: Text(
                "أوافق على إدراج توقيعي في العقد الخاص بي و كذلك في وثيقة الشروط العامة للبيع",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: isConditionOfSignatureChecked,
              onChanged: onCheckBoxChanged,
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

            if (!isConditionOfSignatureChecked) {
              AppToasts.showErrorToast(
                message: "signature_approve".tr(context),
                context: context,
              );
              return;
            }
            showConfirmationDialog();
          },
        ),
      ],
    );
  }
}

class ContractLoading extends StatelessWidget {
  const ContractLoading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.height - 100.sp,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 42.sp,
              width: 42.sp,
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
            // LottieBuilder.asset(AppImages.activationLoading, height: 170.sp, width: 170.sp),
            SizedBox(height: 32.sp),
            Text(
              "generating".tr(context),
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ],
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
