part of 'home_cubit.dart';

@immutable
sealed class HomeState {
  final int unreadCount;
  const HomeState({this.unreadCount = 0});
}

final class HomeInitial extends HomeState {
  const HomeInitial({super.unreadCount});
}

final class HomeBannersLoadedSuccessfully extends HomeState {
  final List<String> bannersUrls;

  const HomeBannersLoadedSuccessfully({required this.bannersUrls, super.unreadCount});
}

final class HomeBannersFailed extends HomeState {
  final String message;

  const HomeBannersFailed({required this.message, super.unreadCount});
}

final class HomeBannersLoading extends HomeState {
  const HomeBannersLoading({super.unreadCount});
}
