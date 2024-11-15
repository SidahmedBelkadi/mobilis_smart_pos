import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/daira_entity.dart';
import 'package:mobilis_smart_pos/src/features/contract/domain/entities/wilaya_entity.dart';

import '../../../features/contract/domain/entities/commune_entity.dart';

class JsonLoaderHelper {
  JsonLoaderHelper._();

  static Future<List<Wilaya>> loadWilayas() async {
    final String response = await rootBundle.loadString('assets/json/states.json');
    final data = await json.decode(response);
    return (data as List).map((json) => Wilaya.fromJson(json)).toList();
  }

  static Future<List<Commune>> loadCommunes() async {
    final String response = await rootBundle.loadString('assets/json/districts.json');
    final data = await json.decode(response) as List;
    return data.map((commune) => Commune.fromJson(commune)).toList();
  }
}
