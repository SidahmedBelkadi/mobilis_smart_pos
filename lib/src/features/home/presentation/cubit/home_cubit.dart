import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:mobilis_smart_pos/src/features/home/domain/use_cases/load_banners_use_case.dart';
import 'package:mobilis_smart_pos/src/features/notifications/domain/use_cases/get_unread_count_use_case.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final LoadBannersUseCase useCase;
  final GetUnreadNotificationsCountUseCase getUnreadNotificationsCountUseCase;

  HomeCubit({
    required this.useCase,
    required this.getUnreadNotificationsCountUseCase,
  }) : super(const HomeInitial());

  Future<void> loadHomeBannersUrls() async {
    emit(HomeBannersLoading(unreadCount: state.unreadCount));

    final failureOrListOfUrls = await useCase();

    failureOrListOfUrls.fold(
      (error) {
        emit(HomeBannersFailed(message: error.message, unreadCount: state.unreadCount));
      },
      (bannersUrls) {
        emit(HomeBannersLoadedSuccessfully(bannersUrls: bannersUrls, unreadCount: state.unreadCount));
      },
    );
    // Fetch unread count after loading banners
    await getUnreadCount();
  }

  Future<void> getUnreadCount() async {
    final result = await getUnreadNotificationsCountUseCase();
    result.fold(
      (failure) => null, // Keep existing count on failure
      (response) {
        if (state is HomeBannersLoadedSuccessfully) {
          emit(HomeBannersLoadedSuccessfully(
            bannersUrls: (state as HomeBannersLoadedSuccessfully).bannersUrls,
            unreadCount: response.unreadCount ?? response.count,
          ));
        } else if (state is HomeBannersFailed) {
          emit(HomeBannersFailed(
            message: (state as HomeBannersFailed).message,
            unreadCount: response.unreadCount ?? response.count,
          ));
        } else {
          emit(HomeInitial(unreadCount: response.unreadCount ?? response.count));
        }
      },
    );
  }
}
