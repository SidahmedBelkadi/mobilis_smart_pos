import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobilis_smart_pos/src/core/commom/loading_button.dart';
import 'package:mobilis_smart_pos/src/core/commom/widgets/custom_app_bar.dart';
import 'package:mobilis_smart_pos/src/core/utils/helpers/toast_helper.dart';
import 'package:mobilis_smart_pos/src/features/sign_in/presentation/cubit/sign_in_cubit.dart';
import 'package:pdfx/pdfx.dart';

import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_elevated_button_text.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/dialog_helper.dart';
import '../../sign_in/domain/entities/sign_in_approve_contract_params.dart';

class PdvEngagmentsScreen extends StatefulWidget {
  const PdvEngagmentsScreen({
    super.key,
    required this.phone,
    required this.refreshToken,
  });

  final String phone;
  final String refreshToken;

  @override
  State<PdvEngagmentsScreen> createState() => _PdvEngagmentsScreenState();
}

class _PdvEngagmentsScreenState extends State<PdvEngagmentsScreen> {
  late PdfControllerPinch pdfControllerPinch;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    pdfControllerPinch = PdfControllerPinch(
      document: PdfDocument.openAsset('assets/pdf/pdv11.pdf'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: CustomAppBar(title: "pdv_contract".tr(context)),
        body: Column(
          children: [
            Expanded(
              child: PdfViewPinch(
                controller: pdfControllerPinch,
              ),
            ),
            SizedBox(height: 24.sp),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 32.0.sp, vertical: 8.sp),
              child: BlocConsumer<SignInCubit, SignInState>(
                listener: (context, state) {
                  if (state is ApproveContractSuccessful) {
                    AppToasts.showSuccessToast(
                        message: state.message.tr(context), context: context);
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(Routes.main, (route) => false);
                  }
                  if (state is ApproveContractFailed) {
                    AppToasts.showErrorToast(
                        message: state.message.tr(context), context: context);
                  }
                },
                builder: (context, state) {
                  if (state is ApproveContractLoading) {
                    return const LoadingButton();
                  }
                  return AppElevatedButtonWithText(
                    text: "accept".tr(context),
                    onPressed: () {
                      AppDialog.showCustomAppDialog(
                        title: '',
                        content: "conditionOfPDV".tr(context),
                        onPressed: () {
                          Navigator.of(context).pop();
                          final SignInApproveContractParams params =
                              SignInApproveContractParams(
                            phone: widget.phone,
                            refreshToken: widget.refreshToken,
                            isConsent: true,
                          );
                          context
                              .read<SignInCubit>()
                              .appoveContract(params: params);
                        },
                        context: context,
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
