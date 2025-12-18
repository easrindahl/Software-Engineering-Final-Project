//! AI-generated code: ViewModel for managing poll voting and results display
import 'package:flutter/foundation.dart';
import 'package:team4_group_project/models/remote_services.dart';
import 'package:team4_group_project/models/user_service.dart' show getCurrentUserId;

class PollViewModel extends ChangeNotifier {
  final RemoteServices _remoteServices = RemoteServices();
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  //! AI-generated code: Vote on a poll option
  Future<bool> voteOnPoll(String eventId, String pollId, String option) async {
    _setLoading(true);
    _error = null;
    try {
      final userId = await getCurrentUserId();
      if (userId.isEmpty) {
        _error = 'Not signed in';
        return false;
      }
      final success = await _remoteServices.voteOnPoll(eventId, pollId, userId, option);
      if (!success) _error = 'Failed to submit vote';
      return success;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('Error voting on poll: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  //! AI-generated code: Remove vote from a poll
  Future<bool> removeVote(String eventId, String pollId) async {
    _setLoading(true);
    _error = null;
    try {
      final userId = await getCurrentUserId();
      if (userId.isEmpty) {
        _error = 'Not signed in';
        return false;
      }
      final success = await _remoteServices.removeVoteFromPoll(eventId, pollId, userId);
      if (!success) _error = 'Failed to remove vote';
      return success;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('Error removing vote: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  //! AI-generated code: Calculate vote counts for display
  Map<String, int> calculateVoteCounts(List<String> options, Map<String, String> votes) {
    Map<String, int> voteCounts = {};
    for (var option in options) {
      voteCounts[option] = 0;
    }
    votes.forEach((userId, option) {
      if (voteCounts.containsKey(option)) {
        voteCounts[option] = voteCounts[option]! + 1;
      }
    });
    return voteCounts;
  }

  //! AI-generated code: Get total vote count
  int getTotalVotes(Map<String, String> votes) {
    return votes.length;
  }

  //! AI-generated code: Get percentage for an option
  double getVotePercentage(String option, Map<String, int> voteCounts, int totalVotes) {
    if (totalVotes == 0) return 0.0;
    return (voteCounts[option] ?? 0) / totalVotes * 100;
  }
}
