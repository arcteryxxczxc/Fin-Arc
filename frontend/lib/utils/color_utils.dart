// lib/utils/color_utils.dart
import 'package:flutter/material.dart';

/// A utility class for color operations
class ColorUtils {
  /// Creates a color with the specified opacity value.
  /// 
  /// This method is a replacement for the deprecated Color.withOpacity() method.
  /// 
  /// [color] The original color
  /// [opacity] The opacity value between 0.0 and 1.0
  /// 
  /// Returns a new color with the given opacity.
  static Color withOpacity(Color color, double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return Color.fromRGBO(
      color.red,
      color.green,
      color.blue,
      opacity,
    );
  }

  /// Lightens a color by the given percentage
  /// 
  /// [color] The original color
  /// [percent] A number between 0 and 100
  /// 
  /// Returns a lightened color
  static Color lighten(Color color, double percent) {
    assert(percent >= 0 && percent <= 100);
    final f = percent / 100;
    return Color.fromARGB(
      color.alpha,
      color.red + ((255 - color.red) * f).round(),
      color.green + ((255 - color.green) * f).round(),
      color.blue + ((255 - color.blue) * f).round(),
    );
  }

  /// Darkens a color by the given percentage
  /// 
  /// [color] The original color
  /// [percent] A number between 0 and 100
  /// 
  /// Returns a darkened color
  static Color darken(Color color, double percent) {
    assert(percent >= 0 && percent <= 100);
    final f = percent / 100;
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 - f)).round(),
      (color.green * (1 - f)).round(),
      (color.blue * (1 - f)).round(),
    );
  }

  /// Creates a color from a hex string (e.g., "#FF0000" for red)
  /// 
  /// [hexString] The hex string representing the color
  /// 
  /// Returns a Color object
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Converts a color to a hex string
  /// 
  /// [color] The color to convert
  /// [withHashSign] Whether to include the leading # sign
  /// 
  /// Returns a hex string
  static String toHex(Color color, {bool withHashSign = true}) {
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    return withHashSign ? '#$hex' : hex;
  }
}