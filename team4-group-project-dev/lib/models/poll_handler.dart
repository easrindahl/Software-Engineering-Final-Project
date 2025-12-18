//models that contain class data and types for app.

import 'package:cloud_firestore/cloud_firestore.dart';

//I will refactor naming for stuff to make it uniform

class PollModel {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String PollId;
  String PollName;
  List<String> Options;
  bool multipleChoices;
  Map<String, String> votes;

  PollModel({
    required this.PollId,
    required this.PollName,
    required this.Options,
    required this.multipleChoices,
    required this.votes,
  });


  factory PollModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PollModel(
      PollId: doc.id,
      PollName: data['PollName'] ?? '',
      Options: List<String>.from(data['Options'] ?? []),
      multipleChoices: data['multipleChoices'] ?? false,
      votes: Map<String, String>.from(data['votes'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'PollId': PollId,
      'PollName': PollName,
      'Options': Options,
      'multipleChoices': multipleChoices,
      'votes': votes,
    };
    return map;
  }

   static Future<void> CreatePoll(String PollId, String PollName,  bool multipleChoices, List<String> Options) async {
      final collectionRef = _firestore.collection('Events');
      final batch = _firestore.batch();
      // create a new doc reference so we can use the generated id
      final newDoc = collectionRef.doc();
      final data = {
        'PollId': newDoc.id,
        'PollName': PollName,
        'Options': Options,
        'multipleChoices': multipleChoices,
        'votes': {},
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(newDoc, data);
      try {
       await batch.commit();
      } catch (e) {
        print('Error creating event: $e');
        rethrow;
      }
  }

  getPollId() {
    return PollId;
  }
  getPollName() {
    return PollName;
  }
  getOptions() {
    return Options;
  }
  getMultipleChoices() {
    return multipleChoices;
  }
  getVotes() {
    return votes;
  }
  //! AI-generated code: Check if a user has already voted
  bool hasUserVoted(String userId) {
    return votes.containsKey(userId);
  }

  //! AI-generated code: Get the option a user voted for
  String? getUserVote(String userId) {
    return votes[userId];
  }

  addVote(String UserId, String Option) async {
    votes[UserId] = Option;
    try {
      //just a safty check, ui should handle verification based on selected vote
      if (Options.contains(Option) == false){
        throw Exception('Invalid option selected');
      }else if (votes.containsKey(UserId) && multipleChoices == false){ //changes vote for that userId
        await _firestore.collection('Polls').doc(PollId).update({'votes.$UserId': Option});
      }else{ 
        await _firestore.collection('Polls').doc(PollId).update({'votes': votes});
      }
    } catch (e) {
      print('Error adding vote: $e');
      rethrow;
    }
  }

  removeVote(String UserId, String Option) async{
    //this needs to be a pair so it only removes the specific option incase its a multi vote.
    votes.removeWhere((key, value) => key == UserId && value == Option);
    try {
      await _firestore.collection('Polls').doc(PollId).update({'votes': votes});
    } catch (e) {
      print('Error removing vote: $e');
      rethrow;
    }
  }

  getVoteCounts() {

    Map<String, int> voteCounts = {};
    for (var option in Options) {
      voteCounts[option] = 0;
    }
    votes.forEach((userId, option) {
      if (voteCounts.containsKey(option)) {
        voteCounts[option] = voteCounts[option]! + 1;
      }
    });
    return voteCounts;
  }

}
