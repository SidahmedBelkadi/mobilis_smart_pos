import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobilis_smart_pos/src/core/api/dio_consumer.dart';
import 'package:mobilis_smart_pos/src/core/api/end_points.dart';

abstract class HomeRemoteDataSource {
  Future<List<String>> loadBanners();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioConsumer dioConsumer;

  HomeRemoteDataSourceImpl({required this.dioConsumer});

  @override
  Future<List<String>> loadBanners() async {
    final response = await dioConsumer.get(EndPoints.getBanners);
    final Map<String, dynamic> decodedJson = jsonDecode(response);
    final List<String> bannersUrls = List<String>.from(decodedJson['imageUrls']);

    debugPrint("=============== $bannersUrls");
    return bannersUrls;
  }
}
