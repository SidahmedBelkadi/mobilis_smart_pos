part of 'offers_cubit.dart';

sealed class OffersState extends Equatable {
  const OffersState();

  @override
  List<Object> get props => [];
}

final class OffersInitial extends OffersState {}

final class GetAllOffersSuccess extends OffersInitial {
  final List<OfferEntity> offers;

  GetAllOffersSuccess({required this.offers});

  @override
  List<Object> get props => [offers];
}

final class GetAllOffersFailure extends OffersInitial {
  final String message;

  GetAllOffersFailure({required this.message});

  @override
  List<Object> get props => [message];
}

final class GetAllOffersLoading extends OffersInitial {}
