import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/camera_screen.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import 'cubit/ocr_cubit.dart';

class PassportOcrScreen extends StatefulWidget {
  const PassportOcrScreen({super.key});

  @override
  State<PassportOcrScreen> createState() => _PassportOcrScreenState();
}

late File? recto;

class _PassportOcrScreenState extends State<PassportOcrScreen> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OcrCubit>();
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => CameraScreen(
                onPictureTaken: (File image) {
                  setState(() {
                    recto = image;
                  });
                  cubit.processPassport(front: image);
                },
              ),
            ));
          },
          child: const Icon(Icons.camera),
        ),
        body: SingleChildScrollView(
          child: Container(
            height: context.height,
            width: context.width,
            padding: EdgeInsets.all(32.sp),
            child: Center(
              child: BlocConsumer<OcrCubit, OcrState>(
                listener: (context, state) {
                  if (state is ProcessPassportFailure) {
                    AppToasts.showErrorToast(
                      message: "Une erreur s'est produite lors du traitement du passeport",
                      context: context,
                    );
                  }
                  if (state is ProcessPassortSuccess) {
                    Navigator.of(context).pushNamed(Routes.contractOcr, arguments: {
                      "isPassport": true,
                      'passportInfo': state.passportResponse,
                      'idCardInfo': null,
                      'recto': recto,
                    });
                  }
                },
                builder: (context, state) {
                  if (state is ProcessPassportLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return Text(
                    "Placez-la sur une surface plane et bien éclairée. Assurez-vous que toute la carte soit visible dans le cadre de la caméra. Le fond doit être noir.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
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
