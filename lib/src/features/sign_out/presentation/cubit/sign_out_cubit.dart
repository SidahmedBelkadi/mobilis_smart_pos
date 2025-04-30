import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mobilis_smart_pos/src/app.dart';
import '../../../../config/routing/app_routes.dart';

import '../../../../dependency_injection/injection_container.dart' as di;
import '../../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../domain/use_cases/sign_out_use_case.dart';

part 'sign_out_state.dart';

class SignOutCubit extends Cubit<SignOutState> with WidgetsBindingObserver {
  final SignOutUseCase useCase;
  final SmartPosLocalStorage localDataSource;

  SignOutCubit({
    required this.useCase,
    required this.localDataSource,
  }) : super(SignOutInitial()) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> signOut(BuildContext context) async {
    emit(SignOutLoading());

    final authResponse = localDataSource.getSavedLoginCredentials();
    if (authResponse != null) {
      final result = await useCase(token: authResponse.refreshToken);
      result.fold(
        (failure) async {
          await di.serviceLocator<SmartPosLocalStorage>().clearLoginCredentials();
          navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
        },
        (_) async {
          await localDataSource.clearLoginCredentials();
          emit(SignOutSuccessful());
        },
      );
    } else {
      await di.serviceLocator<SmartPosLocalStorage>().clearLoginCredentials();
      navigatorKey.currentState?.pushNamedAndRemoveUntil(Routes.signIn, (route) => false);
    }
  }
}
