import 'package:equatable/equatable.dart';

class OfferEntity extends Equatable {
  final int id;
  final String name;
  final int price;
  final String path;

  const OfferEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.path,
  });

  @override
  List<Object?> get props => [id, name, price, path];

  get formattedPrice => '$price DA';

  get formattedPriceAr => 'دج $price';
}
