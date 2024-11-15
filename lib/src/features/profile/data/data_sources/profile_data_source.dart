import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/api/dio_consumer.dart';
import '../../../../core/api/end_points.dart';
import '../models/profile_response_model.dart';

abstract class ProfileDataSource {
  Future<ProfileResponseModel> getPDVInfo({required int pdvID});

  Future<void> updatePDVInfo({
    required String employeeId,
    required String pdvCode,
    required bool isPassport,
    required File recto,
    required File? verso,
    required File commercialRgister,
    required File nif,
  });

  Future<List> getPdvImages({required String pdvCode});
}

class ProfileDataSourceImpl implements ProfileDataSource {
  final DioConsumer dioConsumer;

  ProfileDataSourceImpl({required this.dioConsumer});

  @override
  Future<ProfileResponseModel> getPDVInfo({required int pdvID}) async {
    final response = await dioConsumer.get("${EndPoints.profile}/$pdvID");
    final Map<String, dynamic> decodedData = jsonDecode(response);
    return ProfileResponseModel.fromJson(json: decodedData['pdv']);
  }

  @override
  Future<void> updatePDVInfo({
    required String employeeId,
    required String pdvCode,
    required bool isPassport,
    required File recto,
    required File? verso,
    required File commercialRgister,
    required File nif,
  }) async {
    final formData = FormData.fromMap({
      isPassport ? 'passport' : 'card_id_recto': await MultipartFile.fromFile(
        recto.path,
        filename: '${isPassport ? 'passport' : 'recto'}.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
      if (verso != null)
        'card_id_verso': await MultipartFile.fromFile(
          verso.path,
          filename: 'verso.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      'register_com': await MultipartFile.fromFile(
        commercialRgister.path,
        filename: 'register.png',
        contentType: MediaType('image', 'png'),
      ),
      'nif': await MultipartFile.fromFile(
        nif.path,
        filename: 'nif.png',
        contentType: MediaType('image', 'png'),
      ),
    });

    final uploadRespone = await dioConsumer.put(
      "${EndPoints.uploadPDV}/$pdvCode",
      body: formData,
      formDataIsEnabled: true,
    );

    final folderUrl = jsonDecode(uploadRespone)['folderUrl'];

    await dioConsumer.patch(
      "${EndPoints.updatePDV}/$employeeId",
      body: {
        'folder_files': folderUrl,
      },
    );
  }

  @override
  Future<List> getPdvImages({required String pdvCode}) async {
    final response = await dioConsumer.get("${EndPoints.pdvFolder}/$pdvCode/0");
    final Map<String, dynamic> decodedData = jsonDecode(response);

    return decodedData['imageUrls'];
  }
}
