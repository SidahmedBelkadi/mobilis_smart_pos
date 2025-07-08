import 'package:flutter/material.dart';
import 'package:mobilis_smart_pos/src/core/api/end_points.dart';

class AppColors {
  AppColors._();

  static const _primaryDefault = Colors.green;
  static const _secondaryDefault = Color.fromARGB(255, 146, 219, 97);
  static const _secondaryLightDefault = Color.fromARGB(255, 238, 255, 226);

  static const _primaryGrey = Colors.green;
  static const _secondaryGrey = Color.fromARGB(255, 146, 219, 97);
  static const _secondaryLightGrey = Color.fromARGB(255, 238, 255, 226);

  // Conditional getters
  static Color get primary => EndPoints.isApi1 ? _primaryGrey : _primaryDefault;

  static Color get secondary => EndPoints.isApi1 ? _secondaryGrey : _secondaryDefault;

  static Color get secondaryLight =>
      EndPoints.isApi1 ? _secondaryLightGrey : _secondaryLightDefault;

  static const inputBorder = Color(0xffBABABA);
  static const secondaryText = Color(0xff6E6A7C);
  static const secondaryTextDark = Color(0xff9d99a9);
  static const categoryTextColorGrey = Color(0xff7C7C80);
  static const categorybackgroundColorGrey = Color(0xffF0ECFF);

  // ignore: use_full_hex_values_for_flutter_colors
  static const taskDescription = Color(0xff24252C99);
  static const taskTitle = Color(0xff24252C);
  static const waitingTextColor = Color(0xffFF7D53);
  static final inProgressTextColor = EndPoints.isApi1 ? _primaryGrey : _primaryDefault;
  static const finishedTextColor = Color(0xff0087FF);
  static const inProgressBackgroundColor = categorybackgroundColorGrey;
  static const waittingBackgroundColor = Color(0xffFFE4F2);
  static const finishedBackgroundColor = Color(0xffE3F2FF);
  static const highProiorityColor = waitingTextColor;
  static final mediumProiorityColor = EndPoints.isApi1 ? _primaryGrey : _primaryDefault;
  static const lowProiorityColor = Color(0xff0087FF);
  static const grey = Color(0xffEBE5FF);

  // Background colors
  static const Color darkBackgournd = Color(0xFF272727);

  //Neutral Shades
  static const Color black = Color(0xFF232323);
  static const Color darkerGrey = Color(0xFF4F4F4F);
  static const Color darkGrey = Color(0xFF18191A);
  static const Color softGrey = Color(0xFFF4F4F4);
  static const Color lightGrey = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);
}
