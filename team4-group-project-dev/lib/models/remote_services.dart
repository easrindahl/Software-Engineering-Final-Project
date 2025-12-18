import 'package:cloud_firestore/cloud_firestore.dart';

import 'event_handler.dart';
import 'poll_handler.dart';
import 'user_handler.dart';

//this will be used to the front end to make requests to get class data via firestore
class RemoteServices {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  getUserEvents(String userId) async {
    List<EventModel> userEvents = [];
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Events')
          .where('attendees', arrayContains: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        userEvents.add(EventModel.fromDocument(doc));
      }
    } catch (e) {
      print('Error fetching user events: $e');
    }
    return userEvents;
  }

  getEventPolls(String eventId) async {
    List<PollModel> eventPolls = [];
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Events')
          .doc(eventId)
          .collection('Polls')
          .get();

      for (var doc in querySnapshot.docs) {
        eventPolls.add(PollModel.fromDocument(doc));
      }
    } catch (e) {
      print('Error fetching event polls: $e');
    }
    return eventPolls;
  }

  getUserData(String userId) async {
    UserModel? user;
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Users')
          .doc(userId)
          .get();

      if (doc.exists) {
        user = UserModel.fromDocument(doc);
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return user;
  }

  getEventData(String eventId) async {
    EventModel? event;
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Events')
          .doc(eventId)
          .get();

      if (doc.exists) {
        event = EventModel.fromDocument(doc);
      }
    } catch (e) {
      print('Error fetching event data: $e');
    }
    return event;
  }

  getPollData(String pollId) async {
    PollModel? poll;
    try {
      DocumentSnapshot doc = await _firestore
          .collection('Polls')
          .doc(pollId)
          .get();

      if (doc.exists) {
        poll = PollModel.fromDocument(doc);
      }
    } catch (e) {
      print('Error fetching poll data: $e');
    }
    return poll;
  }

  deleteEvent(String eventId) async {
    try {
      await _firestore.collection('Events').doc(eventId).delete();
    } catch (e) {
      print('Error deleting event: $e');
    }
  }

  Future<String?> createEvent(Map<String, dynamic> data) async {
    try {
      final docRef = await _firestore.collection('Events').add({
        ...data,
        'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  // Toggle RSVP for userId on event eventId. If the user is already an
  // attendee they will be removed, otherwise they will be added
  Future<bool> toggleRsvp(String eventId, String userId) async {
    try {
      final docRef = _firestore.collection('Events').doc(eventId);
      final snapshot = await docRef.get();
      final userDocRef = _firestore.collection('Users').doc(userId);
      final userSnapshot = await userDocRef.get();
      if (!userSnapshot.exists) return false;
      if (!snapshot.exists) return false;
      final attendees = List<String>.from(snapshot.data()?['attendees'] ?? []);
      if (attendees.contains(userId)) {
        await docRef.update({
          'attendees': FieldValue.arrayRemove([userId]),
        });
        await userDocRef.update({
          'events': FieldValue.arrayRemove([eventId]),
        });
      } else {
        await docRef.update({
          'attendees': FieldValue.arrayUnion([userId]),
        });
        await userDocRef.update({
          'events': FieldValue.arrayUnion([eventId]),
        });
      }
      return true;
    } catch (e) {
      print('Error toggling RSVP: $e');
      return false;
    }
  }

  //! AI-generated code: Vote on a poll within an event
  Future<bool> voteOnPoll(String eventId, String pollId, String userId, String option) async {
    try {
      final eventRef = _firestore.collection('Events').doc(eventId);
      final snapshot = await eventRef.get();
      if (!snapshot.exists) return false;

      final data = snapshot.data();
      final polls = List<Map<String, dynamic>>.from(data?['Polls'] ?? []);
      
      // Find the poll and update the vote
      int pollIndex = polls.indexWhere((p) => p['PollId'] == pollId);
      if (pollIndex == -1) return false;

      final poll = polls[pollIndex];
      final votes = Map<String, String>.from(poll['votes'] ?? {});
      
      // Check if option is valid
      final options = List<String>.from(poll['Options'] ?? []);
      if (!options.contains(option)) return false;

      // Update vote (overwrite if user already voted)
      votes[userId] = option;
      polls[pollIndex]['votes'] = votes;

      await eventRef.update({'Polls': polls});
      return true;
    } catch (e) {
      print('Error voting on poll: $e');
      return false;
    }
  }

  //! AI-generated code: Remove a user's vote from a poll
  Future<bool> removeVoteFromPoll(String eventId, String pollId, String userId) async {
    try {
      final eventRef = _firestore.collection('Events').doc(eventId);
      final snapshot = await eventRef.get();
      if (!snapshot.exists) return false;

      final data = snapshot.data();
      final polls = List<Map<String, dynamic>>.from(data?['Polls'] ?? []);
      
      int pollIndex = polls.indexWhere((p) => p['PollId'] == pollId);
      if (pollIndex == -1) return false;

      final poll = polls[pollIndex];
      final votes = Map<String, String>.from(poll['votes'] ?? {});
      votes.remove(userId);
      polls[pollIndex]['votes'] = votes;

      await eventRef.update({'Polls': polls});
      return true;
    } catch (e) {
      print('Error removing vote: $e');
      return false;
    }
  }
}
