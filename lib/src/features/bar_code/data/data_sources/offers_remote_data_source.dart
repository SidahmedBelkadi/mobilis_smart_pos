import 'dart:convert';

import 'package:mobilis_smart_pos/src/core/api/dio_consumer.dart';
import 'package:mobilis_smart_pos/src/core/api/end_points.dart';
import 'package:mobilis_smart_pos/src/features/bar_code/data/models/offer_model.dart';

abstract class OffersRemoteDataSource {
  Future<List<OfferModel>> getAllOffers();
}

class OffersRemoteDataSourceImpl extends OffersRemoteDataSource {
  final DioConsumer dio;

  OffersRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<OfferModel>> getAllOffers() async {
    final rawResponse = await dio.get(EndPoints.getAllOffers);
    final List<dynamic> decodedResponse = jsonDecode(rawResponse);
    final List<OfferModel> offers = decodedResponse.map((e) => OfferModel.fromJson(e)).toList();
    return offers;
  }
}
