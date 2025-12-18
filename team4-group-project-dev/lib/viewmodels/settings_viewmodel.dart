import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:team4_group_project/models/user_service.dart';
import 'package:team4_group_project/models/user_handler.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _uploadingPhoto = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get uploadingPhoto => _uploadingPhoto;
  String? get error => _error;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setUploading(bool v) {
    _uploadingPhoto = v;
    notifyListeners();
  }

  Future<bool> saveProfile(String userId, Map<String, dynamic> data) async {
    _setLoading(true);
    _error = null;
    try {
      await UserService.updateUser(userId, data);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Upload a photo File to Firebase Storage and update user's photoUrl.
  Future<String?> uploadPhoto(File file, String userId) async {
    _setUploading(true);
    _error = null;
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'users/$userId/profile.jpg',
      );
      final uploadTask = ref.putFile(file);
      await uploadTask;
      final url = await ref.getDownloadURL();
      await UserService.updateUser(userId, {'photoUrl': url});
      return url;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setUploading(false);
    }
  }

  /// Expose the current user stream so the View can subscribe via the ViewModel.
  Stream<UserModel?> get userStream => UserService.currentUser;

  /// Return the current user as a Future.
  ///
  /// Use this from Views when you need a one-time snapshot of the current
  /// user (for example to prefill form fields). Prefer `userStream` for
  /// live updates.
  Future<UserModel?> fetchCurrentUser() async {
    final user = await UserService.getCurrentUser();
    return user as UserModel?;
  }
}
