import 'package:flutter/material.dart';

/// Reusable typography and text styles for ClassTrack.
/// Follows the naming convention: fontFamily + fontSize + fontWeight.
/// Defines only typography properties (fontFamily, fontSize, fontWeight) without colors.
abstract final class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'Cairo';

  static const TextStyle cairo22W700 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle cairo22W600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cairo20W600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cairo18W600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cairo16W500 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cairo16W400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle cairo15W500 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cairo15W400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle cairo14W600 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cairo14W400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle cairo13W400 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static TextStyle withColor(TextStyle style, Color color) =>
      style.copyWith(color: color);
}

TextStyle withColor(TextStyle style, Color color) =>
    style.copyWith(color: color);
