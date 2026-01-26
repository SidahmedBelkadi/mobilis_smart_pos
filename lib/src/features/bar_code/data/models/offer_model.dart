import 'package:mobilis_smart_pos/src/features/bar_code/domain/entities/offer_entity.dart';

class OfferModel extends OfferEntity {
  const OfferModel({
    required super.id,
    required super.name,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
