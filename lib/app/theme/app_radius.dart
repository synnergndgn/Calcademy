import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const buttonValue = 14.0;
  static const controlValue = 16.0;
  static const cardValue = 22.0;
  static const heroValue = 28.0;

  static const button = BorderRadius.all(Radius.circular(buttonValue));
  static const control = BorderRadius.all(Radius.circular(controlValue));
  static const card = BorderRadius.all(Radius.circular(cardValue));
  static const hero = BorderRadius.all(Radius.circular(heroValue));
}
