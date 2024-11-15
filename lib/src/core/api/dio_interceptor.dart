import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mobilis_smart_pos/src/app.dart';
import 'package:mobilis_smart_pos/src/config/routing/app_routes.dart';

import '../../../src/dependency_injection/injection_container.dart' as di;
import '../../features/sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../features/sign_in/domain/entities/sign_in_otp_response_entity.dart';
import 'end_points.dart';
import 'status_code.dart';

class DioInterceptor extends Interceptor {
  static const String skipAuthHeader = 'skip-auth';
  final Dio client;
  final SmartPosLocalStorage authLocalDataSource;

  DioInterceptor({
    required this.authLocalDataSource,
    required this.client,
  });

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers[HttpHeaders.acceptHeader] = ContentType.json.toString();

    if (options.headers.containsKey(skipAuthHeader) ||
        options.path == EndPoints.refreshToken) {
      options.headers.remove(skipAuthHeader);
    } else {
      final authResponse =
          authLocalDataSource.getSavedLoginCredentials(); // Await the Future
      if (authResponse != null) {
        options.headers[HttpHeaders.authorizationHeader] =
            'Bearer ${authResponse.accessToken}';
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response); // Continue with the response
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == StatusCode.tokenExpired) {
      final authResponse = authLocalDataSource.getSavedLoginCredentials();
      if (authResponse != null) {
        if (await _refreshToken(authResponse)) {
          handler.resolve(await _retry(err.requestOptions));
          return;
        }
      }
    } else if (err.response?.statusCode == StatusCode.userAccountOnHold) {
      await di.serviceLocator<SmartPosLocalStorage>().clearLoginCredentials();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
      return;
    }
    handler.next(err); // Continue with the error
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );
    return client.request<dynamic>(requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options);
  }

  Future<bool> _refreshToken(SignInOTPResponseEntity authResponse) async {
    final response = await client.post(
      EndPoints.refreshToken,
      data: {
        'token': authResponse.refreshToken,
      },
    );

    if (response.statusCode == StatusCode.ok) {
      final jsonResponse = json.decode(response.data);
      final newAccessToken = jsonResponse["access_token"];

      // Update the AuthResponseModel with the new access token
      final updatedAuthResponse = SignInOTPResponseEntity(
        accessToken: newAccessToken,
        refreshToken: authResponse.refreshToken,
      );

      // Save the new access token in local storage
      await authLocalDataSource.saveLoginCredentials(
          signInResponseEntity: updatedAuthResponse);
      return true;
    } else {
      return false;
    }
  }
}
