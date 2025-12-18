import 'package:flutter/foundation.dart';

class CreateEventViewModel extends ChangeNotifier {
  bool _isSaving = false;
  String? _error;

  bool get isSaving => _isSaving;
  String? get error => _error;

  void _setSaving(bool v) {
    _isSaving = v;
    notifyListeners();
  }

  Future<bool> saveEvent(Map<String, dynamic> eventData) async {
    _setSaving(true);
    _error = null;
    try {
      // Placeholder: actual save logic should call a service to persist to Firestore.
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setSaving(false);
    }
  }
}
