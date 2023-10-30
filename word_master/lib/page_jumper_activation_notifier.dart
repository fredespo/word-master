import 'package:flutter/material.dart';

class PageJumperActivationNotifier extends ChangeNotifier {
  void turnOnPageJumper() {
    notifyListeners();
  }
}
