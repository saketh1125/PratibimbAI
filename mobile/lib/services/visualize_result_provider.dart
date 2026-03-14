import 'package:flutter/foundation.dart';
import '../models/visualize_result.dart';

/// Singleton-style ChangeNotifier that persists the most recent
/// VisualizeResult across ResultScreen ↔ Viewer ↔ ExplanationScreen.
class VisualizeResultProvider extends ChangeNotifier {
  VisualizeResult? _result;

  VisualizeResult? get result => _result;

  void setResult(VisualizeResult value) {
    _result = value;
    notifyListeners();
  }

  void clear() {
    _result = null;
    notifyListeners();
  }
}
