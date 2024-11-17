import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/user_cases/get_pdv_images_use_case.dart';

import '../../../sign_in/data/data_sources/smart_pos_local_storage.dart';
import '../../domain/entities/profile_response_entity.dart';
import '../../domain/user_cases/profile_use_case.dart';
import '../../domain/user_cases/update_profile_use_case.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetProfileInfoUseCase useCase;
  final UpdateProfileUseCase updateUseCase;
  final GetPdvImagesUseCase imagesUseCase;
  final SmartPosLocalStorage authenticationLocalDataSource;

  ProfileCubit({
    required this.useCase,
    required this.authenticationLocalDataSource,
    required this.updateUseCase,
    required this.imagesUseCase,
  }) : super(ProfileInitial());

  Future<void> getPdvInfo() async {
    emit(ProfileInfoLoading());
    final savedCredentials = authenticationLocalDataSource.getSavedLoginCredentials();
    if (savedCredentials != null) {
      if (savedCredentials.userId != null) {
        final failureOrProfileReponseEntity = await useCase(pdvID: savedCredentials.userId!);

        failureOrProfileReponseEntity.fold(
          (error) {
            emit(ProfileInfoFailure(message: error.message));
          },
          (profileInfo) {
            emit(ProfielInfoSuccess(profileResponseEntity: profileInfo));
          },
        );
      } else {
        emit(const ProfileInfoFailure(
          message: "unexpectedError",
        ));
      }
    } else {
      emit(const ProfileInfoFailure(
        message: "unexpectedError",
      ));
    }
  }

  Future<void> updateProfileInfo({
    required bool isPassport,
    required File recto,
    required File? verso,
    required File commercialRgister,
    required File nif,
  }) async {
    emit(UpdateProfileInfoLoading());

    final savedCredentials = await authenticationLocalDataSource.getSavedLoginCredentials();
    if (savedCredentials != null) {
      if (savedCredentials.userId != null && savedCredentials.pdvCode != null) {
        final failureOrVoid = await updateUseCase(
          employeeId: savedCredentials.employeeId.toString(),
          pdvCode: savedCredentials.pdvCode.toString(),
          isPassport: isPassport,
          recto: recto,
          verso: verso,
          commercialRgister: commercialRgister,
          nif: nif,
        );

        failureOrVoid.fold(
          (error) {
            emit(UpdateProfileInfoFailure(message: error.message));
          },
          (_) {
            emit(UpdateProfielInfoSuccess());
          },
        );
      } else {
        emit(const ProfileInfoFailure(
          message: "unexpectedError",
        ));
      }
    } else {
      emit(const ProfileInfoFailure(
        message: "unexpectedError",
      ));
    }
  }

  Future<void> getPdvImages() async {
    emit(GetPdvImagesLoading());
    final savedCredentials = await authenticationLocalDataSource.getSavedLoginCredentials();
    if (savedCredentials != null) {
      if (savedCredentials.userId != null && savedCredentials.pdvCode != null) {
        final failureOrImages = await imagesUseCase(pdvCode: savedCredentials.pdvCode!);
        failureOrImages.fold(
          (error) {
            emit(GetPdvImagesFailure(message: error.message));
          },
          (images) {
            emit(GetPdvImagesSuccess(images: images));
          },
        );
      } else {
        emit(const GetPdvImagesFailure(
          message: "unexpectedError",
        ));
      }
    } else {
      emit(const GetPdvImagesFailure(
        message: "unexpectedError",
      ));
    }
  }
}
