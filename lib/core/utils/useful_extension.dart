import 'package:flutter/material.dart';

extension TextStyleX on TextStyle? {
  TextStyle? get bold => this?.copyWith(fontWeight: FontWeight.bold);
}

extension BuildContextX on BuildContext {
  TextTheme get tt => Theme.of(this).textTheme;
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

extension StringX on String {
  String removePrefix(String prefix) {
    return startsWith(prefix) ? substring(prefix.length) : this;
  }
}
