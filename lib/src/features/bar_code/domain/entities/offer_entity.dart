import 'package:equatable/equatable.dart';

class OfferEntity extends Equatable {
  final int id;
  final String name;

  const OfferEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
