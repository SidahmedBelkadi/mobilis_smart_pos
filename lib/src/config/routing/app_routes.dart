import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/cubit/offers_cubit.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/offers_page.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/sms_cubit.dart';
import 'package:mobilis_smart_pos/src/features/invoices/presentation/cubit/retry_activation/retry_activation_cubit.dart';
import '../../features/contract/presentation/parent_contract_screen.dart';
import '../../features/contract/presentation/parent_preparation_screen.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/profile/presentation/pdv_folder_screen.dart';
import '../../features/profile/presentation/update_pdv_folder.dart';

import '../../core/animation/routes_animation_manager.dart';
import '../../dependency_injection/injection_container.dart';
import '../../features/OCR/presentation/cubit/ocr_cubit.dart';
import '../../features/OCR/presentation/id_ocr_screen.dart';
import '../../features/OCR/presentation/ocr_preparation_screen.dart';
import '../../features/OCR/presentation/passport_ocr_screen.dart';
import '../../features/bar_code/presentation/bar_code_screen.dart';
import '../../features/contract/domain/entities/contract_request_params_entitiy.dart';
import '../../features/contract/presentation/choose_card_option_screen.dart';
import '../../features/contract/presentation/contract_generated_screen.dart';
import '../../features/contract/presentation/contract_screen.dart';
import '../../features/contract/presentation/cubit/contract_cubit.dart';
import '../../features/contract/presentation/mrz/mrz_details.dart';
import '../../features/contract/presentation/mrz/mrz_preparation_screen.dart';
import '../../features/contract/presentation/mrz/parent_ocr_details_screen.dart';
import '../../features/contract/presentation/nfc/nfc_preparation_screen.dart';
import '../../features/contract/presentation/nfc/nfc_reader_screen.dart';
import '../../features/contract/presentation/ocr/mrz_ocr_screen.dart';
import '../../features/contract/presentation/ocr/parent_mrz_ocr.dart';
import '../../features/contract/presentation/signature_screen.dart';
import '../../features/e-payment/presentation/e-payment_screen.dart';
import '../../features/e-rselli/presentation/e-rselli_screen.dart';
import '../../features/forgot_password/presentation/cubit/forgot_password_cubit.dart';
import '../../features/forgot_password/presentation/forgot_password_otp_screen.dart';
import '../../features/forgot_password/presentation/forgot_password_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/invoices/presentation/cubit/invoices_cubit.dart';
import '../../features/invoices/presentation/invoices_screen.dart';
import '../../features/main/presentation/main_screen.dart';
import '../../features/on_boarding/presentation/on_boarding_screen.dart';
import '../../features/on_boarding/presentation/pdv_engagments_screen.dart';
import '../../features/profile/presentation/widget/password_update.dart';
import '../../features/sign_in/domain/entities/sign_in_request_params.dart';
import '../../features/sign_in/presentation/cubit/sign_in_cubit.dart';
import '../../features/sign_in/presentation/otp_screen.dart';
import '../../features/sign_in/presentation/sign_in_screen.dart';

class Routes {
  Routes._();

  static const String onBoarding = "/on_boarding";
  static const String pdvEngagements = "/pdv_engagement";
  static const String main = "/main";
  static const String signIn = "/sign_in";
  static const String forgotPassword = "/forgot_pasword";
  static const String forgotPasswordOTP = "/forgot_pasword_otp";
  static const String chooseCardOption = "/choose_card_option";
  static const String mrzPreparation = "/mrz_preparation";
  static const String mrzOcr = "/mrz_ocr";
  static const String parentMrzOcr = "/parent_mrz_ocr";
  static const String parentContract = "/parent_contract";
  static const String nfcPreparation = "/nfc_preparation";
  static const String nfcReader = "/nfc_reader";
  static const String objectDetection = "/object_detection_screen";
  static const String ocrPreparation = "/ocr_preparation";
  static const String ocrPassport = "/ocr_passport";
  static const String ocrIdCard = "/ocr_id";
  static const String mrzDetails = "mrz_details";
  static const String parentMrzOcrDetails = "parent_mrz_details";
  static const String parentPreparation = "paranetPreparation";
  static const String pdvFolder = "/pdv_folder";
  static const String updatePdvFolder = "/update_pdv_folder";
  static const String signUpV1 = "/sign_up1";
  static const String signUpV2 = "/sign_up2";
  static const String signUpV3 = "/sign_up3";
  static const String home = "/home";
  static const String erselli = "/e_rsseli";
  static const String epayment = "/e_payment";
  static const String invoices = "/invoices";
  static const String otp = "/otp";
  static const String contract = "/contract";
  static const String contractOcr = "/contract_ocr";
  static const String barCode = "/bar_code";
  static const String offers = "/offers";
  static const String signatureScreen = "/signature";
  static const String test = "/test";
  static const String contractGenerated = "/contract_generated";
  static const String changePassword = "/profile_change_password";
}

class AppRoutes {
  static Route? onGenerateRoute(RouteSettings routeSettings) {
    final args = routeSettings.arguments;

    switch (routeSettings.name) {
      case Routes.onBoarding:
        return RoutesAnimationManager.slideFromRightTransition(
          const OnBoardingScreen(),
        );
      case Routes.pdvEngagements:
        final params = args as Map<String, dynamic>;
        return RoutesAnimationManager.slideFromRightTransition(
          BlocProvider(
            create: (_) => serviceLocator<SignInCubit>(),
            child: PdvEngagmentsScreen(
              phone: params['phone'],
              refreshToken: params['refresh_token'],
            ),
          ),
        );
      case Routes.main:
        final params = args as Map<String, dynamic>?;
        return RoutesAnimationManager.slideFromRightTransition(
          MainScreen(
            index: params?['index'],
            fromSignin: params?['fromSignin'],
          ),
        );

      case Routes.contractGenerated:
        return RoutesAnimationManager.slideFromRightTransition(const ContractGenerated());

      case Routes.signIn:
        return RoutesAnimationManager.slideFromRightTransition(
          BlocProvider(
            create: (_) => serviceLocator<SignInCubit>(),
            child: const SignInScreen(),
          ),
        );
      case Routes.forgotPassword:
        final params = args as Map<String, dynamic>;

        return RoutesAnimationManager.slideFromRightTransition(
          BlocProvider(
            create: (_) => serviceLocator<ForgotPasswordCubit>(),
            child: ForgotPasswordScreen(
              msisdn: params["msisdn"],
            ),
          ),
        );
      case Routes.forgotPasswordOTP:
        final params = args as Map<String, dynamic>;
        return RoutesAnimationManager.slideFromRightTransition(
          BlocProvider(
            create: (_) => serviceLocator<ForgotPasswordCubit>(),
            child: ForgotPasswordOtpScreen(
              msisdn: params['msisdn'] as String,
            ),
          ),
        );

      case Routes.changePassword:
        return RoutesAnimationManager.slideFromRightTransition(
          BlocProvider(
            create: (_) => serviceLocator<ForgotPasswordCubit>(),
            child: const ProfilePasswordUpdateScreen(),
          ),
        );
      case Routes.otp:
        final params = args as Map<String, dynamic>;
        return RoutesAnimationManager.slideFromRightTransition(
          BlocProvider(
            create: (_) => serviceLocator<SignInCubit>(),
            child: OTPScreen(
              signInParams: params['params'] as SignInRequestParams,
              responseParams: params['responseParams'],
            ),
          ),
        );
      case Routes.chooseCardOption:
        return RoutesAnimationManager.slideFromRightTransition(
          const ChooseCardOptionScreen(),
          args: args,
        );
      case Routes.mrzPreparation:
        final params = args as Map<String, dynamic>;
        return RoutesAnimationManager.slideFromRightTransition(
          MrzPreparationScreen(
            isPassport: params['isPassport'],
          ),
          args: args,
        );
      case Routes.mrzOcr:
        final params = args as Map<String, dynamic>;
        return RoutesAnimationManager.slideFromRightTransition(
          MrzOCRScreen(
            documentType: params['documentType'],
          ),
          args: args,
        );

      case Routes.parentMrzOcr:
        final params = args as Map<String, dynamic>;
        return RoutesAnimationManager.slideFromRightTransition(
          ParentMrzOCRScreen(
            documentType: params['documentType'],
            minorContract: params['minorContract'] as ContractRequestParamsEntitiy,
            minorRecto: params['minorRecto'] as File?,
            minorVerso: params['minorVerso'] as File?,
            minorIsPassport: params['minorIsPassport'] as bool,
            parentIsPassport: params['parentIsPassport'] as bool,
          ),
          args: args,
        );
      case Routes.nfcPreparation:
        return RoutesAnimationManager.slideFromRightTransition(
          const NfcPreparationScreen(),
        );
      case Routes.mrzDetails:
        final params = args as Map<String, dynamic>;
        return RoutesAnimationManager.slideFromRightTransition(
          MrzDetailsScreen(
            documentNumber: params['documentNumber'],
            dateOfBirth: params['dateOfBirth'],
            dateOfExpiry: params['dateOfExpiry'],
            docType: params['docType'],
          ),
          args: args,
        );

      case Routes.parentMrzOcrDetails:
        final params = args as Map<String, dynamic>;
        return RoutesAnimationManager.slideFromRightTransition(
          ParentOcrDetails(
            documentNumber: params['documentNumber'],
            dateOfBirth: params['dateOfBirth'],
            dateOfExpiry: params['dateOfExpiry'],
            docType: params['docType'],
            minorContract: params['minorContract'] as ContractRequestParamsEntitiy,
            minorRecto: params['minorRecto'] as File?,
            minorVerso: params['minorVerso'] as File?,
            minorIsPassport: params['minorIsPassport'] as bool,
            parentIsPassport: params['parentIsPassport'] as bool,
          ),
          args: args,
        );

      case Routes.parentPreparation:
        final params = args as Map<String, dynamic>;

        return RoutesAnimationManager.slideFromRightTransition(
          ParentPreparationScreen(
            contract: params['contract'] as ContractRequestParamsEntitiy,
            recto: params['recto'] as File?,
            verso: params['verso'] as File?,
            isPassport: params['isPassport'] as bool,
          ),
        );

      case Routes.nfcReader:
        final params = args as Map<String, dynamic>;

        return RoutesAnimationManager.slideFromRightTransition(
          NfcReaderScreen(
            documentNumber: params['documentNumber'],
            dateOfBirth: params['dateOfBirth'],
            dateOfExpiry: params['dateOfExpiry'],
            docType: params['docType'],
            isMinor: params['isMinor'],
            minorContract: params['minorContract'] as ContractRequestParamsEntitiy?,
            minorRecto: params['minorRecto'] as File?,
            minorVerso: params['minorVerso'] as File?,
            minorIsPassport: params['minorIsPassport'] as bool?,
            parentIsPassport: params['parentIsPassport'] as bool?,
          ),
        );

      case Routes.parentContract:
        final params = args as Map<String, dynamic>;

        return RoutesAnimationManager.slideFromRightTransition(
          ParentContractScreen(
            minorContract: params['minorContract'],
            minorRecto: params['minorRecto'],
            minorVerso: params['minorVerso'],
            minorIsPassport: params['minorIsPassport'],
            parentIsPassport: params['parentIsPassport'],
            parentExtractedNFCData: params['parentExtractedNFCData'],
          ),
        );

      case Routes.ocrPreparation:
        final params = args as Map<String, dynamic>;

        return RoutesAnimationManager.slideFromRightTransition(
          OcrPreparationScreen(isPassport: params['isPassport'] as bool),
        );
      case Routes.ocrPassport:
        return RoutesAnimationManager.slideFromRightTransition(
          BlocProvider(
            create: (_) => serviceLocator<OcrCubit>(),
            child: const PassportOcrScreen(),
          ),
        );
      case Routes.ocrIdCard:
        return RoutesAnimationManager.slideFromRightTransition(
          BlocProvider(
            create: (_) => serviceLocator<OcrCubit>(),
            child: const IdCardOcrScreen(),
          ),
        );
      case Routes.home:
        return RoutesAnimationManager.slideFromRightTransition(
          args: args,
          const HomeScreen(),
        );
      case Routes.erselli:
        return RoutesAnimationManager.slideFromRightTransition(
          args: args,
          const ErselliScreen(),
        );

      case Routes.epayment:
        return RoutesAnimationManager.slideFromRightTransition(
          args: args,
          const PaymentScreen(),
        );

      case Routes.invoices:
        return RoutesAnimationManager.slideFromRightTransition(
          args: args,
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => serviceLocator<InvoicesCubit>()..getInvoices(isFirstTime: true),
              ),
              BlocProvider(
                create: (context) => serviceLocator<RetryActivationCubit>(),
              ),
              BlocProvider(
                create: (context) => serviceLocator<ContractCubit>(),
              ),
            ],
            child: const InvoicesScreen(),
          ),
        );

      case Routes.pdvFolder:
        return RoutesAnimationManager.slideFromRightTransition(
          args: args,
          const PdvFolderScreen(),
        );

      case Routes.updatePdvFolder:
        return RoutesAnimationManager.slideFromRightTransition(
          args: args,
          BlocProvider(
            create: (_) => serviceLocator<ProfileCubit>(),
            child: const UpdatePdvFolder(),
          ),
        );

      case Routes.contract:
        final params = args as Map<String, dynamic>;

        return RoutesAnimationManager.slideFromRightTransition(
          args: args,
          ContractScreen(
            metaData: params['data'] as Map,
            isMinor: params['isMinor'],
            isPresumed: params['isPresumed'],
          ),
        );

      case Routes.barCode:
        final params = args as Map<String, dynamic>;

        return RoutesAnimationManager.slideFromRightTransition(
          args: args,
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => serviceLocator<ContractCubit>(),
              ),
            ],
            child: SimScannerScreen(
              contract: params['contract'] as ContractRequestParamsEntitiy,
              recto: params['recto'] as File?,
              verso: params['verso'] as File?,
              isPassport: params['isPassport'] as bool,
              parentRecto: params['parentRecto'],
              parentVerso: params['parentVerso'],
              justificatif: params['justificatif'],
              parentIsPassport: params['parentIsPassport'],
            ),
          ),
        );

      case Routes.offers:
        return RoutesAnimationManager.slideFromBottomTransition(
          args: args,
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => serviceLocator<OffersCubit>(),
              ),
            ],
            child: const OffersPage(),
          ),
        );

      case Routes.signatureScreen:
        final params = args as Map<String, dynamic>;

        return RoutesAnimationManager.slideFromRightTransition(
          args: args,
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => serviceLocator<ContractCubit>(),
              ),
              BlocProvider(
                create: (context) => serviceLocator<SmsCubit>(),
              ),
            ],
            child: SignatureScreen(
              contract: params['contract'] as ContractRequestParamsEntitiy,
              formattedSmsCode: params['formattedSmsCode'] as String,
              recto: params['recto'] as File?,
              verso: params['verso'] as File?,
              isPassport: params['isPassport'] as bool,
              parentRecto: params['parentRecto'],
              parentVerso: params['parentVerso'],
              justificatif: params['justificatif'],
              parentIsPassport: params['parentIsPassport'],
            ),
          ),
        );
    }
    return null;
  }
}
