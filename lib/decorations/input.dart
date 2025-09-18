import 'package:flutter/material.dart';

class input {
  static InputDecoration inputdecoration(String? Text, Icon? icon) {
    return InputDecoration(
      labelText: Text,
      prefixIcon: icon,
    );
  }
}
