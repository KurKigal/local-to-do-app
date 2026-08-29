import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const instant =
      Duration(milliseconds: 90);

  static const fast =
      Duration(milliseconds: 140);

  static const standard =
      Duration(milliseconds: 190);

  static const emphasized =
      Duration(milliseconds: 240);

  static const curve =
      Curves.easeOutCubic;

  static const emphasizedCurve =
      Curves.easeInOutCubic;

  static Duration resolve(
    BuildContext context,
    Duration preferred,
  ) {
    return MediaQuery.disableAnimationsOf(
      context,
    )
        ? Duration.zero
        : preferred;
  }
}
