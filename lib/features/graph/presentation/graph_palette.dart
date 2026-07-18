import 'package:calcademy/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class GraphPalette {
  static const _light = <Color>[
    AppColors.forest,
    Color(0xFF356AA0),
    Color(0xFF9A5B27),
    Color(0xFF73528E),
    Color(0xFF287C78),
  ];

  static const _dark = <Color>[
    Color(0xFFAFCBBD),
    Color(0xFF86B9EC),
    AppColors.dataPoint,
    Color(0xFFC4A1DF),
    Color(0xFF74C9C2),
  ];

  static Color colorFor(BuildContext context, int index) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? _dark
        : _light;
    return palette[index % palette.length];
  }
}
