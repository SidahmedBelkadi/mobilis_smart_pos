part of 'home_cubit.dart';

@immutable
sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeBannersLoadedSuccessfully extends HomeInitial {
  final List<String> bannersUrls;

  HomeBannersLoadedSuccessfully({required this.bannersUrls});
}

final class HomeBannersFailed extends HomeInitial {
  final String message;

  HomeBannersFailed({required this.message});
}

final class HomeBannersLoading extends HomeInitial {}
