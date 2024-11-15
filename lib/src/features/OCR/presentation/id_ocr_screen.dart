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

class IdCardOcrScreen extends StatefulWidget {
  const IdCardOcrScreen({super.key});

  @override
  State<IdCardOcrScreen> createState() => _IdCardOcrScreenState();
}

late File recto;
late File verso;

class _IdCardOcrScreenState extends State<IdCardOcrScreen> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OcrCubit>();
    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
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
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    "Veuillez maintenant capturer le verso de votre carte d'identité. Assurez-vous que l'image est nette et que toutes les informations sont bien visibles. Placez la carte sur une surface plane, bien éclairée, et évitez les reflets.",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('OK'),
                      onPressed: () async {
                        Navigator.of(context).pop();

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CameraScreen(
                              onPictureTaken: (File image) {
                                setState(() {
                                  verso = image;
                                  cubit.processId(front: recto, back: verso);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
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
                  if (state is ProcessIDCardFailure) {
                    AppToasts.showErrorToast(
                      message:
                          "Une erreur s'est produite lors du traitement de la carte d'identité",
                      context: context,
                    );
                  }
                  if (state is ProcessIDCardSuccess) {
                    Navigator.of(context).pushNamed(Routes.contractOcr, arguments: {
                      "isPassport": false,
                      'passportInfo': null,
                      'idCardInfo': state.idCardResponse,
                      'recto': recto,
                      'verso': verso,
                    });
                  }
                },
                builder: (context, state) {
                  if (state is ProcessIDCardLoading) {
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
