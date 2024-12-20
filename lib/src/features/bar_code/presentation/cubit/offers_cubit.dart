import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/entities/offer_entity.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/domain/use_cases/get_all_offers_use_case.dart';

part 'offers_state.dart';

class OffersCubit extends Cubit<OffersState> {
  final GetAllOffersUseCase offersUseCase;

  OffersCubit({
    required this.offersUseCase,
  }) : super(OffersInitial());

  Future<void> getAllOffers() async {
    emit(GetAllOffersLoading());

    final failureOrOffers = await offersUseCase();

    failureOrOffers.fold(
      (error) {
        emit(GetAllOffersFailure(message: error.message));
      },
      (offers) {
        emit(GetAllOffersSuccess(offers: offers));
      },
    );
  }
}
