import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lottie/lottie.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_floating_action_button.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/app_localization_helper.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/media_query_values.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_colors.dart';
import 'package:mobilis_smart_pos/src/core/utils/ressources/app_images.dart';
import 'package:mobilis_smart_pos/src/features/profile/presentation/widget/personnel_files_update_notice.dart';
import 'package:mobilis_smart_pos/src/features/profile/presentation/widget/upload_image_field.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/utils/enums/documents_type.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import 'cubit/profile_cubit.dart';

class UpdatePdvFolder extends StatefulWidget {
  const UpdatePdvFolder({super.key});

  @override
  State<UpdatePdvFolder> createState() => _UpdatePdvFolderState();
}

class _UpdatePdvFolderState extends State<UpdatePdvFolder> {
  File? recto;
  File? verso;
  File? commercialRegister;
  File? nif;
  bool isPassport = false;
  bool isIdCard = false;
  bool isUploading = false;
  final TextRecognizer recognizer = TextRecognizer();

  @override
  Widget build(BuildContext context) {
    bool _isDocumentRecognizedText(String text, DocumentsType docType) {
      if (docType == DocumentsType.frontIdCard) {
        final pattern9Digits = RegExp(r'\b\d{9}\b');
        final has9Digits = pattern9Digits.hasMatch(text);
        return has9Digits;
      } else if (docType == DocumentsType.backIdCard) {
        final patternIdDza = RegExp(r'IDDZA');
        final patternName = RegExp(r'Nom');
        final patternSymol = RegExp(r'<<<');

        final hasIdDza = patternIdDza.hasMatch(text);
        final hasName = patternName.hasMatch(text);
        final hasSymbols = patternSymol.hasMatch(text);
        return (hasIdDza && hasName && hasSymbols);
      } else if (docType == DocumentsType.passport) {
        final patternP = RegExp(r'P<');
        final pattern9Digits = RegExp(r'\b\d{9}\b');

        final hasP = patternP.hasMatch(text);
        final has9Digits = pattern9Digits.hasMatch(text);
        return hasP && has9Digits;
      } else if (docType == DocumentsType.nif) {
        /* final nifPattern = RegExp(r'NIF\s*:\s*(\d{20})');
        final match = nifPattern.hasMatch(text);
        return match;*/
        return true;
      } else if (docType == DocumentsType.commercialRegister) {
        // Todo : Add Commercial Register Here
        return true;
      } else {
        return false;
      }
    }

    Future<bool> checkDocument(
        {required TextRecognizer recognizer,
        required File file,
        required DocumentsType docType}) async {
      final document = InputImage.fromFile(file);
      final recognizedText = await recognizer.processImage(document);
      final isDocumentRecognized =
          _isDocumentRecognizedText(recognizedText.text, docType);
      return isDocumentRecognized;
    }

    Future<void> captureDocument({
      required TextRecognizer recognizer,
      required DocumentsType docType,
      required BuildContext context,
    }) async {
      final imagesPath = await CunningDocumentScanner.getPictures(
          noOfPages: 1, isGalleryImportAllowed: false);
      if (imagesPath != null && imagesPath.isNotEmpty) {
        File file = File(imagesPath[0]);
        final validated = await checkDocument(
            recognizer: recognizer, file: file, docType: docType);
        if (validated) {
          if (docType == DocumentsType.passport) {
            setState(() {
              recto = file;
            });
          } else if (docType == DocumentsType.frontIdCard) {
            setState(() {
              recto = file;
            });
          } else if (docType == DocumentsType.backIdCard) {
            setState(() {
              verso = file;
            });
          } else if (docType == DocumentsType.commercialRegister) {
            setState(() {
              commercialRegister = file;
            });
          } else if (docType == DocumentsType.nif) {
            setState(() {
              nif = file;
            });
          }
        } else {
          AppToasts.showWarningToast(
              message: "incorrect_image".tr(context), context: context);
          return;
        }
      } else {
        return;
      }
    }

    void _showDrawer(BuildContext parentContext) {
      showModalBottomSheet(
        backgroundColor:
            parentContext.isDarkMode ? AppColors.darkGrey : Colors.white,
        showDragHandle: true,
        context: parentContext,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('identity_card'.tr(context)),
                onTap: () {
                  setState(() {
                    isPassport = false;
                    isIdCard = true;
                  });
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: Text('passport'.tr(context)),
                onTap: () {
                  setState(() {
                    isPassport = true;
                    isIdCard = false;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    bool _areAllDocumentsUploaded() {
      if (isPassport && !isUploading) {
        return recto != null && commercialRegister != null && nif != null;
      } else if (isIdCard && !isUploading) {
        return recto != null &&
            verso != null &&
            commercialRegister != null &&
            nif != null;
      }
      return false;
    }

    return SafeArea(
      child: Scaffold(
        floatingActionButton: _areAllDocumentsUploaded()
            ? CustomFAB(
                label: "update_now".tr(context),
                icon: FontAwesomeIcons.upload,
                onPressed: () {
                  context.read<ProfileCubit>().updateProfileInfo(
                        isPassport: isPassport,
                        recto: recto!,
                        verso: verso,
                        commercialRgister: commercialRegister!,
                        nif: nif!,
                      );
                },
              )
            : null,
        appBar: CustomAppBar(title: "update_my_folder".tr(context)),
        body: Container(
          height: context.height,
          width: context.width,
          padding: EdgeInsets.all(24.sp),
          child: BlocConsumer<ProfileCubit, ProfileState>(
            listener: (context, state) {
              if (state is UpdateProfileInfoLoading) {
                setState(() {
                  isUploading = true;
                });
              }
              if (state is UpdateProfielInfoSuccess) {
                AppToasts.showSuccessToast(
                  message: "files_uploaded_successfully".tr(context),
                  context: context,
                );
                Navigator.of(context).pushReplacementNamed(
                  Routes.pdvFolder,
                );
              }
              if (state is UpdateProfileInfoFailure) {
                AppToasts.showErrorToast(
                  message: "server_error_occurred".tr(context),
                  context: context,
                );
              }
            },
            builder: (context, state) {
              if (state is UpdateProfileInfoLoading) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LottieBuilder.asset(
                        AppImages.uploading,
                        height: 180.sp,
                        width: 200,
                      ),
                      SizedBox(height: 16.sp),
                      Text(
                        "uploading".tr(context),
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    ],
                  ),
                );
              }
              return ListView(
                children: [
                  if (!_areAllDocumentsUploaded())
                    const PersonnelFilesUpdateNotice(),
                  SizedBox(height: 16.sp),
                  isIdCard
                      ? Column(
                          children: [
                            recto != null
                                ? Image.file(
                                    recto!,
                                    height: 180.sp,
                                    width: context.width,
                                  )
                                : UploadImageField(
                                    label: "recto".tr(context),
                                    onTap: () {
                                      captureDocument(
                                          recognizer: recognizer,
                                          docType: DocumentsType.frontIdCard,
                                          context: context);
                                    },
                                    icon: FontAwesomeIcons.camera,
                                  ),
                            SizedBox(height: 24.sp),
                            verso != null
                                ? Image.file(
                                    verso!,
                                    height: 180.sp,
                                    width: context.width,
                                  )
                                : UploadImageField(
                                    label: "verso".tr(context),
                                    onTap: () {
                                      captureDocument(
                                          recognizer: recognizer,
                                          docType: DocumentsType.backIdCard,
                                          context: context);
                                    },
                                    icon: FontAwesomeIcons.camera,
                                  ),
                          ],
                        )
                      : SizedBox(),
                  if (isPassport)
                    recto != null
                        ? Image.file(
                            recto!,
                            height: 180.sp,
                            width: context.width,
                          )
                        : UploadImageField(
                            label: "Passport",
                            onTap: () {
                              captureDocument(
                                  recognizer: recognizer,
                                  docType: DocumentsType.passport,
                                  context: context);
                            },
                            icon: FontAwesomeIcons.camera,
                          ),
                  if (!isPassport && !isIdCard)
                    UploadImageField(
                      label: "identity_card_or_passport".tr(context),
                      onTap: () => _showDrawer(context),
                      icon: FontAwesomeIcons.camera,
                    ),
                  SizedBox(height: 24.sp),
                  commercialRegister != null
                      ? Image.file(
                          commercialRegister!,
                          height: 180.sp,
                          width: context.width,
                        )
                      : UploadImageField(
                          label: "commercial_register".tr(context),
                          onTap: () {
                            captureDocument(
                                recognizer: recognizer,
                                docType: DocumentsType.commercialRegister,
                                context: context);
                          },
                          icon: FontAwesomeIcons.camera,
                        ),
                  SizedBox(height: 24.sp),
                  nif != null
                      ? Image.file(
                          nif!,
                          height: 180.sp,
                          width: context.width,
                        )
                      : UploadImageField(
                          label: "nif".tr(context),
                          onTap: () {
                            captureDocument(
                                recognizer: recognizer,
                                docType: DocumentsType.nif,
                                context: context);
                          },
                          icon: FontAwesomeIcons.camera,
                        ),
                  SizedBox(
                    height: 80,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
