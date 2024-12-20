import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../config/routing/app_routes.dart';
import '../../../core/commom/widgets/app_elevated_button_text.dart';
import '../../../core/commom/widgets/custom_appbar_with_deny_contract.dart';
import '../../../core/utils/helpers/app_localization_helper.dart';
import '../../../core/utils/helpers/media_query_values.dart';
import '../../../core/utils/helpers/toast_helper.dart';
import '../../../core/utils/ressources/app_colors.dart';
import '../../../core/utils/ressources/app_images.dart';
import '../../contract/domain/entities/contract_request_params_entitiy.dart';
import '../../contract/presentation/cubit/contract_cubit.dart';

class SimScannerScreen extends StatefulWidget {
  const SimScannerScreen({
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
  SimScannerScreenState createState() => SimScannerScreenState();
}

late ContractCubit cubit;
late ContractRequestParamsEntitiy newContract;
String? selectedOfferName;

class SimScannerScreenState extends State<SimScannerScreen> {
  static const platform = MethodChannel("channel");

  @override
  void initState() {
    cubit = context.read<ContractCubit>();
    super.initState();
  }

  Future<void> _startBarcodeScanner() async {
    try {
      final result = await platform.invokeMethod("startBarcodeScanner");
      _showBarcodeDialog(context, result);
    } on PlatformException catch (e) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomAppbarWithDenyContract(
          title: "scan_sim".tr(context),
          showProgressIndicator: true,
          currentStep: widget.parentRecto != null ? 7 : 4,
          allSteps: widget.parentRecto != null ? 8 : 5,
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            height: context.height - 56.sp,
            width: context.width,
            child: BlocConsumer<ContractCubit, ContractState>(
              listener: (context, state) {
                if (state is CheckBeforeEditContractSuccess) {
                  Navigator.of(context).pushNamed(
                    Routes.signatureScreen,
                    arguments: {
                      'contract': newContract,
                      'formattedSmsCode': state.formattedStringWithoutSpaces,
                      'recto': widget.recto,
                      'verso': widget.verso,
                      'isPassport': widget.isPassport,
                      'parentRecto': widget.parentRecto,
                      'parentVerso': widget.parentVerso,
                      'justificatif': widget.justificatif,
                      'parentIsPassport': widget.parentIsPassport
                    },
                  );
                }
                if (state is CheckBeforeEditContractFailed) {
                  AppToasts.showErrorToast(
                    message: state.message.tr(context),
                    context: context,
                  );
                }
              },
              builder: (context, state) {
                if (state is CheckBeforeEditContractLoading) {
                  return Stack(
                    children: [
                      SimScannerBody(onPressed: () {}),
                      ModalBarrier(
                        color: Colors.black.withOpacity(0.3),
                        dismissible: false,
                      ),
                      Center(
                        child: Container(
                          height: 56.sp,
                          width: 56.sp,
                          padding: EdgeInsets.all(12.sp),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12.sp),
                          ),
                          child: LottieBuilder.asset(AppImages.loading),
                        ),
                      ),
                    ],
                  );
                }
                return SimScannerBody(
                  onPressed: _startBarcodeScanner,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBarcodeDialog(BuildContext context, String barcode) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('scanned_bar_code'.tr(context)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  barcode,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 16.h),
                Text('scanned_bar_code_question'.tr(context)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('discard'.tr(context)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('yes'.tr(context)),
              onPressed: () async {
                Navigator.of(context).pop();
                final Map? selectedOffer =
                    await Navigator.of(context).pushNamed(Routes.offers) as Map?;

                if (selectedOffer != null) {
                  debugPrint("======= SELECTED OFFER ID : ${selectedOffer['offerId']}");
                  debugPrint("======= SELECTED OFFER NAME : ${selectedOffer['offerName']}");
                  // Use the selected offer name to continue
                  _continueWithBarcode(context, barcode, selectedOffer['offerId']);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _continueWithBarcode(BuildContext context, String barcode, int selectedOfferId) {
    setState(() {
      newContract = widget.contract.copyWith(
        serialNumber: int.parse(barcode),
        subscriptionId: selectedOfferId,
      );
    });

    cubit.checkBeforeEditContract(
      contract: newContract,
    );
  }
}

class OffersSkeleton extends StatelessWidget {
  const OffersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Container(
        padding: EdgeInsets.all(16.0.sp),
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Text(
              "Available Offers",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24.sp),
            Expanded(
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (context, index) => OfferItem(
                  title: "Offer Name",
                  price: '2000 DA',
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OfferItem extends StatelessWidget {
  const OfferItem({
    super.key,
    required this.title,
    required this.price,
    this.onTap,
    this.isSelected = false,
  });

  final String title;
  final String price;
  final void Function()? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.sp),
        padding: EdgeInsets.symmetric(vertical: 10.sp),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.all(
            Radius.circular(10.sp),
          ),
        ),
        child: ListTile(
          title: Text(title),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                price,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isSelected)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 8.sp,
                    ),
                    Container(
                      padding: EdgeInsets.all(5.sp),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.all(Radius.circular(12.sp)),
                      ),
                      child: Icon(
                        FontAwesomeIcons.check,
                        size: 16.sp,
                        color: Colors.white,
                      ),
                    )
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}

class SimScannerBody extends StatelessWidget {
  const SimScannerBody({super.key, this.onPressed});

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.height,
      width: context.width,
      padding: EdgeInsets.all(32.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(AppImages.barCodeAnimation5, height: 200.h, width: 200.w),
          SizedBox(height: 32.h),
          Text(
            "bar_code_instruction".tr(context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: AppColors.primary,
                ),
          ),
          SizedBox(height: 64.h),
          AppElevatedButtonWithText(
            text: "start_button".tr(context),
            onPressed: onPressed,
          )
        ],
      ),
    );
  }
}
