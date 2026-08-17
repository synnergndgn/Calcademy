import 'package:flutter/material.dart';

abstract final class AppRadius {
  // Restrained radii keep the UI closer to a notebook/instrument panel than
  // a stack of interchangeable SaaS cards.
  static const buttonValue = 8.0;
  static const controlValue = 10.0;
  static const cardValue = 10.0;
  static const heroValue = 14.0;

  static const button = BorderRadius.all(Radius.circular(buttonValue));
  static const control = BorderRadius.all(Radius.circular(controlValue));
  static const card = BorderRadius.all(Radius.circular(cardValue));
  static const hero = BorderRadius.all(Radius.circular(heroValue));
}
