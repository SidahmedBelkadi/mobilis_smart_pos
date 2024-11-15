import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/api/dio_consumer.dart';
import '../../../../core/api/end_points.dart';
import '../models/id_card_response_model.dart';
import '../models/passport_response_model.dart';

abstract class OcrDataSource {
  Future<IdCardResponseModel> processId({required File front, required File back});
  Future<PassportResponseModel> processPassport({required File front});
}

class OcrDataSourceImpl implements OcrDataSource {
  final DioConsumer dioConsumer;

  OcrDataSourceImpl({required this.dioConsumer});

  @override
  Future<IdCardResponseModel> processId({
    required File front,
    required File back,
  }) async {
    final formData = FormData.fromMap({
      'image_data_front': await MultipartFile.fromFile(
        front.path,
        filename: 'recto_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
      'image_data_back': await MultipartFile.fromFile(
        back.path,
        filename: 'verso_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    final response = await dioConsumer.post(EndPoints.processId,
        body: formData, formDataIsEnabled: true, includeToken: false);

    return IdCardResponseModel.fromJson(json: jsonDecode(response));
  }

  @override
  Future<PassportResponseModel> processPassport({required File front}) async {
    final formData = FormData.fromMap({
      'image_data': await MultipartFile.fromFile(
        front.path,
        filename: 'passport_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    final response = await dioConsumer.post(
      EndPoints.processPassport,
      body: formData,
      formDataIsEnabled: true,
      includeToken: false,
    );

    return PassportResponseModel.fromJson(json: jsonDecode(response));
  }
}
