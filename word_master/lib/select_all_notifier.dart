import 'package:flutter/material.dart';

class SelectAllNotifier extends ChangeNotifier {
  void triggerSelectAll() {
    notifyListeners();
  }
}
