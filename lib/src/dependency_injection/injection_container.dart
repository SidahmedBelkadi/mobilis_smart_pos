import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/data/data_sources/offers_remote_data_source.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/data/repositories/offers_repository_impl.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/repositories/offers_repository.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/use_cases/get_all_offers_use_case.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/presentation/cubit/offers_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/rasd_edit_contract_use_case.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/rasd_generate_contract_use_case.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/rasd_trigger_sms_use_case.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/retry_sms_use_case.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/use_cases/trigger_sms_use_case.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/rasd/rasd_contract_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/rasd/rasd_sms_cubit.dart';
import 'package:mobilis_smart_pos/src/features/contract/presentation/cubit/sms_cubit.dart';
import 'package:mobilis_smart_pos/src/features/home/data/data_sources/home_remote_data_source.dart';
import 'package:mobilis_smart_pos/src/features/home/data/repository/home_repository_impl.dart';
import 'package:mobilis_smart_pos/src/features/home/domain/repository/home_repository.dart';
import 'package:mobilis_smart_pos/src/features/home/domain/use_cases/load_banners_use_case.dart';
import 'package:mobilis_smart_pos/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:mobilis_smart_pos/src/features/invoices/domain/use_cases/retry_activation_use_case.dart';
import 'package:mobilis_smart_pos/src/features/invoices/presentation/cubit/retry_activation/retry_activation_cubit.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/dio_interceptor.dart';
import '../core/networking/network_info.dart';
import '../core/utils/helpers/launch_helper.dart';
import '../core/utils/helpers/route_helper.dart';
import '../features/OCR/data/data_sources/ocr_data_source.dart';
import '../features/OCR/data/repositories/ocr_repository_impl.dart';
import '../features/OCR/domain/repositories/ocr_repository.dart';
import '../features/OCR/domain/use_cases/process_id_card_use_case.dart';
import '../features/OCR/domain/use_cases/process_passport_use_case.dart';
import '../features/OCR/presentation/cubit/ocr_cubit.dart';
import '../features/contract/data/data_sources/contract_remote_data_source.dart';
import '../features/contract/data/repositories/contract_repository_impl.dart';
import '../features/contract/domain/repositories/contract_repository.dart';
import '../features/contract/domain/use_cases/check_before_edit_contract_use_case.dart';
import '../features/contract/domain/use_cases/edit_contract_use_case.dart';
import '../features/contract/domain/use_cases/generate_contract_use_case.dart';
import '../features/contract/presentation/cubit/contract_cubit.dart';
import '../features/forgot_password/data/data_sources/reset_password_remote_data_source.dart';
import '../features/forgot_password/data/repositories/reset_password_repository_impl.dart';
import '../features/forgot_password/domain/repositories/reset_password_repository.dart';
import '../features/forgot_password/domain/use_cases/reset_password_otp_use_case.dart';
import '../features/forgot_password/domain/use_cases/reset_password_use_case.dart';
import '../features/forgot_password/presentation/cubit/forgot_password_cubit.dart';
import '../features/invoices/data/data_sources/invoices_remote_data_source.dart';
import '../features/invoices/data/repositories/invoices_repository_impl.dart';
import '../features/invoices/domain/repositories/invoices_repository.dart';
import '../features/invoices/domain/use_cases/get_invoices_use_case.dart';
import '../features/invoices/presentation/cubit/invoices_cubit.dart';
import '../features/main/presentation/cubits/cubit/locale_cubit.dart';
import '../features/profile/data/data_sources/profile_data_source.dart';
import '../features/profile/data/reopsitories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/user_cases/get_pdv_images_use_case.dart';
import '../features/profile/domain/user_cases/profile_use_case.dart';
import '../features/profile/domain/user_cases/update_profile_use_case.dart';
import '../features/profile/presentation/cubit/profile_cubit.dart';
import '../features/sign_in/data/data_sources/sign_in_remote_data_source.dart';
import '../features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../features/sign_in/data/repositories/sign_in_repository_impl.dart';
import '../features/sign_in/domain/repositories/sign_in_repository.dart';
import '../features/sign_in/domain/use_cases/approve_contract_use_case.dart';
import '../features/sign_in/domain/use_cases/sign_in_use_case.dart';
import '../features/sign_in/domain/use_cases/verify_otp_use_case.dart';
import '../features/sign_in/presentation/cubit/sign_in_cubit.dart';
import '../features/sign_out/data/data_sources/sign_out_data_source.dart';
import '../features/sign_out/data/repositories/sign_out_repository_impl.dart';
import '../features/sign_out/domain/repositories/sign_out_repository.dart';
import '../features/sign_out/domain/use_cases/sign_out_use_case.dart';
import '../services/upgrader_service.dart';

final serviceLocator = GetIt.instance;

Future<void> initializeAppDependencies() async {
  // ================ EXTERNAL ================ //
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  serviceLocator.registerLazySingleton(() => secureStorage);
  serviceLocator.registerLazySingleton(() => sharedPreferences);

  // =============== API ====================== //

  final dio = Dio();
  serviceLocator.registerLazySingleton(() => dio);
  serviceLocator.registerLazySingleton<DioInterceptor>(
    () => DioInterceptor(
      client: dio,
      authLocalDataSource: serviceLocator(),
    ),
  );
  dio.interceptors.add(PrettyDioLogger(
    requestHeader: true,
    requestBody: true,
    responseHeader: true,
    responseBody: true,
    error: true,
    compact: true,
    maxWidth: 90,
  ));
  // serviceLocator.registerLazySingleton<DioConsumer>(() => DioConsumer(client: dio));

  serviceLocator
      .registerLazySingleton(() => UpgraderService(dio: serviceLocator()));

  // =============== CORE ====================== //
  serviceLocator.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(connectivity: Connectivity()));

  // =============== UTILS ====================== //
  serviceLocator.registerLazySingleton(
    () => LaunchHelper(sharedPreferences: serviceLocator()),
  );

  // =============== HELPERS ====================== //
  serviceLocator.registerLazySingleton(() => InitialRouteHelper(
        launchHelper: serviceLocator<LaunchHelper>(),
        authLocalDataSource: serviceLocator<SmartPosLocalStorage>(),
      ));

  // ================ DATA SOURCES ================ //
  serviceLocator.registerLazySingleton<SignInRemoteDataSource>(
      () => SignInRemoteDataSourceImpl(dioConsumer: serviceLocator()));
  serviceLocator.registerLazySingleton<SmartPosLocalStorage>(
      () => SmartPosLocalStorageImpl(sharedPreferences: serviceLocator()));
  serviceLocator.registerLazySingleton<SignoutRemoteDataSource>(
      () => SignoutRemoteDataSourceImpl(dioConsumer: serviceLocator()));
  serviceLocator.registerLazySingleton<ContractRemoteDataSource>(
      () => ContractRemoteDataSourceImpl(dioConsumer: serviceLocator()));
  serviceLocator.registerLazySingleton<ResetPasswordRemoteDataSource>(
      () => ResetPasswordRemoteDataSourceImpl(dioConsumer: serviceLocator()));
  serviceLocator.registerLazySingleton<InvoicesRemoteDataSource>(
      () => InvoicesRemoteDataSourceImpl(dioConsumer: serviceLocator()));
  serviceLocator.registerLazySingleton<OcrDataSource>(
      () => OcrDataSourceImpl(dioConsumer: serviceLocator()));

  serviceLocator.registerLazySingleton<ProfileDataSource>(
      () => ProfileDataSourceImpl(dioConsumer: serviceLocator()));

  serviceLocator.registerLazySingleton<OffersRemoteDataSource>(
      () => OffersRemoteDataSourceImpl(dio: serviceLocator()));
  serviceLocator.registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(dioConsumer: serviceLocator()));
  // ================ REPOSITORIES ================ //

  serviceLocator.registerLazySingleton<SignInRepository>(
    () => SignInRepositoryImpl(
      networkInfo: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<SignOutRepository>(
    () => SignOutRepositoryImpl(
      networkInfo: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<ContractRepository>(
    () => ContractRepositoryImpl(
      networkInfo: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<ResetPasswordRepository>(
    () => ResetPasswordRepositoryImpl(
      networkInfo: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<InvoicesRepository>(
    () => InvoicesRepositoryImpl(
      networkInfo: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );
  serviceLocator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      networkInfo: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<OcrRepository>(
    () => OcrRepositoryImpl(
      networkInfo: serviceLocator(),
      dataSource: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<OffersRepository>(
    () => OffersRepositoryImpl(
      networkInfo: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );

  serviceLocator.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      networkInfo: serviceLocator(),
      remoteDataSource: serviceLocator(),
    ),
  );

  // ================ USE CASES ================ //

  serviceLocator
      .registerLazySingleton(() => SignInUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => VerifyOtpUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => ApproveContractUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => SignOutUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => CheckBeforeEditContractUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => EditContractUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => GenerateContractUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => ResetPasswordUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => ResetPasswordOTPUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => GetInvoicesUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => RetryActivationUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => GetProfileInfoUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => ProcessIdCardUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => ProcessPassportUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => UpdateProfileUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => GetPdvImagesUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => GetAllOffersUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => TrigggerSmsUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => RetryTrigggerSmsUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => RasdEditContractUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => RasdGenerateContractUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => RasdTrigggerSmsUseCase(repository: serviceLocator()));
  serviceLocator.registerLazySingleton(
      () => LoadBannersUseCase(repository: serviceLocator()));
  // ================ BLOCS ================ //

  serviceLocator.registerFactory(() => SignInCubit(
        signInUseCase: serviceLocator(),
        verifyOtpUseCase: serviceLocator(),
        approveContractUseCase: serviceLocator(),
        localDataSource: serviceLocator(),
      ));
  // serviceLocator.registerFactory(
  //     () => SignOutCubit(useCase: serviceLocator(), localDataSource: serviceLocator()));
  serviceLocator.registerFactory(() => ContractCubit(
        checkBeforeEditContractUseCase: serviceLocator(),
        editContractUseCase: serviceLocator(),
        authenticationLocalDataSource: serviceLocator(),
        generateContractUseCase: serviceLocator(),
      ));
  serviceLocator.registerFactory(
    () => LocaleCubit(),
  );
  serviceLocator.registerFactory(() => ForgotPasswordCubit(
        otpUseCase: serviceLocator(),
        resetPasswordUseCase: serviceLocator(),
        authenticationLocalDataSource: serviceLocator(),
      ));
  serviceLocator.registerFactory(
    () => InvoicesCubit(
      useCase: serviceLocator(),
      authenticationLocalDataSource: serviceLocator(),
    ),
  );

  serviceLocator.registerFactory(
    () => RetryActivationCubit(
      useCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory(
    () => ProfileCubit(
      useCase: serviceLocator(),
      authenticationLocalDataSource: serviceLocator(),
      updateUseCase: serviceLocator(),
      imagesUseCase: serviceLocator(),
    ),
  );
  serviceLocator.registerFactory(() => OcrCubit(
      idCardUseCase: serviceLocator(), passportUseCase: serviceLocator()));

  serviceLocator
      .registerFactory(() => OffersCubit(offersUseCase: serviceLocator()));
  serviceLocator.registerFactory(() =>
      SmsCubit(useCase: serviceLocator(), retryUseCase: serviceLocator()));

  serviceLocator.registerFactory(() => RasdContractCubit(
        rasdEditContractUseCase: serviceLocator(),
        rasdGenerateContractUseCase: serviceLocator(),
        smartPosLocalStorage: serviceLocator(),
      ));

  serviceLocator.registerFactory(() => RasdSmsCubit(
        rasdTrigggerSmsUseCase: serviceLocator(),
        smartPosLocalStorage: serviceLocator(),
      ));

  serviceLocator.registerFactory(() => HomeCubit(
        useCase: serviceLocator(),
      ));
}
