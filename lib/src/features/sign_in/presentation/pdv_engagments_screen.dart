import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

import '../../../core/commom/loading_button.dart';
import '../../../core/commom/widgets/custom_app_bar.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import 'cubit/sign_in_cubit.dart';
import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_elevated_button_text.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';

class PdvEngagmentsScreen extends StatefulWidget {
  const PdvEngagmentsScreen({
    super.key,
  });

  @override
  State<PdvEngagmentsScreen> createState() => _PdvEngagmentsScreenState();
}

class _PdvEngagmentsScreenState extends State<PdvEngagmentsScreen> {
  PdfControllerPinch? pdfControllerPinch;
  final GlobalKey<SfSignaturePadState> _signaturePadKey = GlobalKey();
  bool _isPdfValidated = false;
  bool _errorLoadingPdf = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final cubit = context.read<SignInCubit>();
    try {
      final pdfBytes = await cubit.getPdvContract();
      if (pdfBytes.isEmpty) throw Exception("Empty PDF data");

      final document = await PdfDocument.openData(pdfBytes);
      setState(() {
        pdfControllerPinch = PdfControllerPinch(document: Future.value(document));
      });
    } catch (e) {
      setState(() {
        _errorLoadingPdf = true;
      });
    }
  }

  late File signatureFile;
  String? signatureImagePath;
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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SignInCubit>();

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: CustomAppBar(title: "pdv_contract".tr(context)),
        body: pdfControllerPinch == null && !_errorLoadingPdf
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: PdfViewPinch(controller: pdfControllerPinch!),
                  ),
                  SizedBox(height: 24.sp),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0.sp, vertical: 8.sp),
                    child: BlocConsumer<SignInCubit, SignInState>(
                      listener: (context, state) {
                        if (state is ApproveContractSuccessful) {
                          AppToasts.showSuccessToast(
                            message: "Contrat signé avec succès",
                            context: context,
                          );
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.main,
                            (route) => false,
                          );
                        }
                        if (state is ApproveContractFailed) {
                          AppToasts.showErrorToast(
                            message: state.message.tr(context),
                            context: context,
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is ApproveContractLoading) {
                          return const LoadingButton();
                        }
                        if (state is ApproveContractFailed) {
                          return Center(
                            child: Column(
                              children: [
                                Text("Failed to get the contract"),
                                ElevatedButton(
                                    onPressed: () {
                                      // TODO : Retry
                                    },
                                    child: Text("Réssayer")),
                              ],
                            ),
                          );
                        }
                        return AppElevatedButtonWithText(
                          text: "Signer le contrat",
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (context) {
                                return Padding(
                                  padding: EdgeInsets.all(16.sp),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 12.sp),
                                      Text(
                                        "signature_pdv_contrat".tr(context),
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      SizedBox(height: 16.sp),
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
                                              _isPdfValidated = true;
                                            });
                                            return false;
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 24.sp),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey,
                                              minimumSize: Size(context.width * 0.35, 48.h),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isPdfValidated = false;
                                              });
                                              _signaturePadKey.currentState?.clear();
                                            },
                                            child: const Text(
                                              "Supprimer",
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              minimumSize: Size(context.width * 0.35, 48.h),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () async {
                                              if (!_isPdfValidated) return;
                                              Navigator.of(context).pop();
                                              final file = await _saveSignature();
                                              setState(() {
                                                signatureFile = file;
                                              });

                                              cubit.signAndApproveContract(
                                                signatureFile: signatureFile,
                                              );
                                            },
                                            child: Text(
                                              "confirm".tr(context),
                                              style: TextStyle(color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 24.sp),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
