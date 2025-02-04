import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:mobilis_smart_pos/src/features/home/domain/use_cases/load_banners_use_case.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final LoadBannersUseCase useCase;

  HomeCubit({required this.useCase}) : super(HomeInitial());

  Future<void> loadHomeBannersUrls() async {
    emit(HomeBannersLoading());

    final failureOrListOfUrls = await useCase();

    failureOrListOfUrls.fold(
      (error) {
        emit(HomeBannersFailed(message: error.message));
      },
      (bannersUrls) {
        emit(HomeBannersLoadedSuccessfully(bannersUrls: bannersUrls));
      },
    );
  }
}
