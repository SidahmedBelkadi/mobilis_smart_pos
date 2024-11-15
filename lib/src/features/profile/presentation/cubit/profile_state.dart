part of 'profile_cubit.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object> get props => [];
}

final class ProfileInitial extends ProfileState {}

final class ProfielInfoSuccess extends ProfileState {
  final ProfileResponseEntity profileResponseEntity;

  const ProfielInfoSuccess({required this.profileResponseEntity});

  @override
  List<Object> get props => [profileResponseEntity];
}

final class ProfileInfoFailure extends ProfileState {
  final String message;

  const ProfileInfoFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class ProfileInfoLoading extends ProfileState {}

// =================== UPDATE PDV INFO ================ //

final class UpdateProfielInfoSuccess extends ProfileState {}

final class UpdateProfileInfoFailure extends ProfileState {
  final String message;

  const UpdateProfileInfoFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class UpdateProfileInfoLoading extends ProfileState {}

// =================== Get PDV Folder ================ //
final class GetPdvImagesSuccess extends ProfileState {
  final List images;

  const GetPdvImagesSuccess({required this.images});

  @override
  List<Object> get props => [images];
}

final class GetPdvImagesFailure extends ProfileState {
  final String message;

  const GetPdvImagesFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class GetPdvImagesLoading extends ProfileState {}
