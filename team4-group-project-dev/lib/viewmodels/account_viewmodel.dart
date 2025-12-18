import 'package:flutter/foundation.dart';
import 'package:team4_group_project/models/user_handler.dart';
import 'package:team4_group_project/models/user_service.dart';

class AccountViewModel extends ChangeNotifier {
  UserModel? user;
  bool _loading = false;
  bool get loading => _loading;

  /// Load the current user. If [userId] is provided, it may be used in the
  /// future; currently we load the authenticated user's profile via UserService.
  Future<void> getUserPage(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await UserService.getCurrentUser();
      if (result is UserModel) {
        user = result;
      } else {
        // fallback to an empty user to keep the UI simple
        user = UserModel(id: '', name: '', email: '');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading user page: $e');
      user = UserModel(id: '', name: '', email: '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
