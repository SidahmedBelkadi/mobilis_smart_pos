import '../../../config/routing/app_routes.dart';
import '../../../features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../../features/sign_in/domain/entities/sign_in_otp_response_entity.dart';
import 'launch_helper.dart';

class InitialRouteHelper {
  final LaunchHelper launchHelper;
  final SmartPosLocalStorage authLocalDataSource;

  InitialRouteHelper({
    required this.launchHelper,
    required this.authLocalDataSource,
  });

  String determineInitialRoute() {
    final bool isFirstTime = launchHelper.isFirstTime();
    final SignInOTPResponseEntity? authResponse =
        authLocalDataSource.getSavedLoginCredentials();

    if (isFirstTime) {
      return Routes.onBoarding;
    } else if (authResponse != null && authResponse.accessToken.isNotEmpty) {
      return Routes.main;
    } else {
      return Routes.signIn;
    }
  }
}
