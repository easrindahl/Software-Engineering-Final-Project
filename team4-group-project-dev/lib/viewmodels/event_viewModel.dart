import 'package:flutter/foundation.dart';
import 'package:team4_group_project/models/remote_services.dart';
import 'package:team4_group_project/models/user_service.dart'
    show getCurrentUserId;

class EventViewModel extends ChangeNotifier {
  final RemoteServices _remoteServices = RemoteServices();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Load events for the current user
  Future<void> getEvents() async {
    _setLoading(true);
    _error = null;
    try {
      final userid = await getCurrentUserId();
      await _remoteServices.getUserEvents(userid);
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('Error loading events: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle RSVP for the currently-signed in user on [eventId] 
  //Returns true when the operation succeeds 
  Future<bool> rsvpToEvent(String eventId) async {
    _setLoading(true);
    _error = null;
    try {
      final userId = await getCurrentUserId();
      if (userId.isEmpty) {
        _error = 'Not signed in';
        return false;
      }
      final ok = await _remoteServices.toggleRsvp(eventId, userId);
      if (!ok) _error = 'Failed to update RSVP';
      return ok;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('Error toggling RSVP: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
