import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/camera_screen.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import 'cubit/profile_cubit.dart';
import 'widget/personnel_files_update_notice.dart';
import 'widget/upload_image_field.dart';

class ProfilePersonnelFilesUpdate extends StatefulWidget {
  const ProfilePersonnelFilesUpdate({
    super.key,
  });

  @override
  State<ProfilePersonnelFilesUpdate> createState() =>
      _ProfilePersonnelFilesUpdate();
}

class _ProfilePersonnelFilesUpdate extends State<ProfilePersonnelFilesUpdate> {
  File? recto;
  File? verso;
  File? commercialRegister;
  File? nif;
  bool isPassport = false;

  Future<bool> _checkPermissions() async {
    final cameraStatus = await Permission.camera.request();

    if (cameraStatus.isGranted) {
      return true;
    } else {
      _showPermissionDeniedDialog();
      return false;
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('camera_permission_title'.tr(context)),
          content: Text('camera_permission_instruction'.tr(context)),
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
            )
          ],
        );
      },
    );
  }

  Future<void> _showImageDialog({
    required BuildContext parentContext,
    required String title,
    required VoidCallback onOk,
  }) async {
    return showDialog<void>(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: onOk,
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showDrawer(BuildContext parentContext) {
    showModalBottomSheet(
      showDragHandle: true,
      context: parentContext,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('passport'.tr(context)),
              onTap: () async {
                Navigator.of(context).pop();
                setState(() {
                  isPassport = true;
                });

                if (await _checkPermissions()) {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      onPictureTaken: (File image) {
                        setState(() {
                          recto = image;
                        });
                      },
                    ),
                  ));
                }
              },
            ),
            ListTile(
              title: Text('identity_card'.tr(context)),
              onTap: () async {
                Navigator.of(context).pop();
                setState(() {
                  isPassport = false;
                });

                if (await _checkPermissions()) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        onPictureTaken: (File image) {
                          setState(() {
                            recto = image;
                          });
                        },
                      ),
                    ),
                  );

                  // Show dialog after capturing recto
                  if (recto != null) {
                    _showImageDialog(
                      parentContext: parentContext,
                      title: "verso_instruction".tr(parentContext),
                      onOk: () async {
                        Navigator.of(parentContext).pop();

                        if (await _checkPermissions()) {
                          Navigator.of(parentContext).push(
                            MaterialPageRoute(
                              builder: (context) => CameraScreen(
                                onPictureTaken: (File image) {
                                  setState(() {
                                    verso = image;
                                  });
                                },
                              ),
                            ),
                          );
                        }
                      },
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          children: [
            if (isPassport &&
                    (recto == null ||
                        commercialRegister == null ||
                        nif == null) ||
                !isPassport &&
                    (recto == null ||
                        verso == null ||
                        commercialRegister == null ||
                        nif == null))
              const PersonnelFilesUpdateNotice(),
            SizedBox(height: 32.h),
            if ((isPassport && recto == null) ||
                (!isPassport && (recto == null || verso == null)))
              UploadImageField(
                label: "${"identity_document".tr(context)} : ",
                onTap: () => _showDrawer(context),
              ),
            if (commercialRegister == null) SizedBox(height: 16.h),
            if (commercialRegister == null)
              UploadImageField(
                label: "${"commercial_register".tr(context)} : ",
                onTap: () async {
                  if (await _checkPermissions()) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        onPictureTaken: (File image) {
                          setState(() {
                            commercialRegister = image;
                          });
                        },
                      ),
                    ));
                  }
                },
              ),
            if (nif == null) SizedBox(height: 16.h),
            if (nif == null)
              UploadImageField(
                label: "nif".tr(context),
                onTap: () async {
                  if (await _checkPermissions()) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CameraScreen(
                        onPictureTaken: (File image) {
                          setState(() {
                            nif = image;
                          });
                        },
                      ),
                    ));
                  }
                },
              ),
            if ((isPassport && recto != null) ||
                (!isPassport && recto != null && verso != null) &&
                    commercialRegister != null &&
                    nif != null)
              BlocConsumer<ProfileCubit, ProfileState>(
                listener: (context, state) {
                  if (state is UpdateProfielInfoSuccess) {
                    AppToasts.showSuccessToast(
                      message: "files_uploaded_successfully".tr(context),
                      context: context,
                    );
                    Navigator.of(context).pushNamedAndRemoveUntil(
                        Routes.main, (route) => false,
                        arguments: {
                          'index': 2,
                        });
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
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if ((isPassport &&
                          recto != null &&
                          commercialRegister != null &&
                          nif != null) ||
                      (!isPassport &&
                          recto != null &&
                          verso != null &&
                          commercialRegister != null &&
                          nif != null)) {
                    return SizedBox(
                      height: context.height / 2.5,
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<ProfileCubit>().updateProfileInfo(
                                  isPassport: isPassport,
                                  recto: recto!,
                                  verso: verso,
                                  commercialRgister: commercialRegister!,
                                  nif: nif!,
                                );
                          },
                          child: Text('submit'.tr(context)),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
          ],
        ),
      ),
    ); // Display Images Later Here
  }
}
