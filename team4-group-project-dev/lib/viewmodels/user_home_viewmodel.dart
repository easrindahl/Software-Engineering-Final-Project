import 'package:flutter/foundation.dart';

// Minimal ViewModel for the user home screen.
// Expand with business logic (events, user info) as needed.
class UserHomeViewModel extends ChangeNotifier {
  bool isLoading = false;

  // Placeholder initialization hook.
  Future<void> init() async {
    // load data here when necessary
  }
}
