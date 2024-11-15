import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';

class OcrPreparationScreen extends StatelessWidget {
  const OcrPreparationScreen({super.key, required this.isPassport});
  final bool isPassport;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          foregroundColor: Colors.black,
          backgroundColor: AppColors.secondary,
          title: Text(
            'OCR',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            if (isPassport) {
              Navigator.of(context).pushNamed(Routes.ocrPassport);
            } else {
              Navigator.of(context).pushNamed(Routes.ocrIdCard);
            }
          },
          label: Row(
            children: [
              const Text(
                "Continuer",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 5.sp),
              const Icon(CupertinoIcons.right_chevron)
            ],
          ),
          backgroundColor: AppColors.secondary,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(32.0.sp, 32.0.sp, 32.0.sp, 96.0.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeaderText(context),
                SizedBox(height: 8.h),
                _buildLottieAnimation(),
                SizedBox(height: 48.h),
                _buildInstructionStep(
                  title: '1. Positionnement du Document :',
                  description:
                      '- Placez votre pièce d\'identité sous l\'appareil de manière à ce qu\'elle soit bien centrée.\n'
                      '- Assurez-vous que tous les bords du document sont visibles et non coupés.',
                ),
                SizedBox(height: 24.h),
                _buildInstructionStep(
                  title: '2. Conditions de Scan :',
                  description: '- Utilisez un fond noir pour garantir un contraste optimal.\n'
                      '- Évitez les reflets et les ombres sur le document.\n'
                      '- Assurez-vous que la pièce d\'identité est propre et sans taches.',
                ),
                SizedBox(height: 24.h),
                _buildInstructionStep(
                  title: '3. Processus de Scan :',
                  description: '- Restez immobile pendant le scan.\n'
                      '- Attendez jusqu\'à la fin du processus de reconnaissance optique des caractères (OCR) avant de retirer votre document.',
                ),
                SizedBox(height: 32.h),
                _buildFooterText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText(BuildContext context) {
    return Text(
      'Veuillez suivre les instructions ci-dessous pour un scan optimal de votre pièce d\'identité :',
      style: Theme.of(context).textTheme.headlineSmall,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLottieAnimation() {
    return Center(
      child: Lottie.asset(AppImages.chooseScanAnimation, height: 220.h, width: 220.w),
    );
  }

  Widget _buildInstructionStep({required String title, required String description}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.only(left: 10.sp),
          child: Text(
            description,
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterText() {
    return Text(
      'Merci de suivre ces recommandations pour assurer une reconnaissance précise et rapide de votre pièce d\'identité.',
      style: TextStyle(
        fontSize: 14.sp,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
        color: AppColors.secondaryText,
      ),
    );
  }
}
