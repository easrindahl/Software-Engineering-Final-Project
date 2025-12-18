//models that contain class data and types for app.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  String id;
  String name;
  String email;
  // Editable profile fields type beat
  String bio;
  String photoUrl;
  String phone;
  String address;

  GeoPoint? UserGeoPoint;

  Timestamp? createdAt;
  //I LOVE LISTS YAYYYYY (shouts out python lists)
  List<String>? tools;
  List<String>? games;
  List<String>? events; // Event IDs, not EventModel objects

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.bio = '',
    this.photoUrl = '',
    this.phone = '',
    this.address = '',
    this.UserGeoPoint,
    this.tools,
    this.games,
    this.events,
    this.createdAt,
  });

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      bio: data['bio'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      phone: data['phone'] ?? '',
      tools: List<String>.from(data['tools'] ?? []),
      games: List<String>.from(data['games'] ?? []),
      // Events field contains event IDs (strings), not EventModel objects
      events: (data['events'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList()
          .cast<String>(),
      address: data['address'] ?? '',
      UserGeoPoint: data['UserGeoPoint'],
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'bio': bio,
      'photoUrl': photoUrl,
      'phone': phone,
      'tools': tools,
      'games': games,
      'address': address,
      'UserGeoPoint': UserGeoPoint,
      'events': events,
    };

    if (createdAt != null) {
      map['createdAt'] = createdAt;
    }

    return map;
  }

  // Editable fields mutators
  void changeName(String newName) {
    name = newName;
  }

  void changeBio(String newBio) {
    bio = newBio;
  }

  void changePhotoUrl(String newPhotoUrl) {
    photoUrl = newPhotoUrl;
  }

  void changePhone(String newPhone) {
    phone = newPhone;
  }

  void addTools(String newTool) {
    tools ??= [];
    tools!.add(newTool);
  }

  void addGames(String newGame) {
    games ??= [];
    games!.add(newGame);
  }

  // Accessors
  String getName() {
    return name;
  }

  String getBio() {
    return bio;
  }

  //not sure why u would want this but i guess it may be handy!
  String getPhotoUrl() {
    return photoUrl;
  }

  String getPhone() {
    return phone;
  }

  List<String>? getTools() {
    return tools;
  }

  String getToolsAsString() {
    return tools?.join(', ') ?? '';
  }

  List<String>? getGames() {
    return games;
  }

  List<String>? getEvents() {
    return events;
  }

  String getId() {
    return id;
  }

  void deleteTool(String tool) {
    tools?.remove(tool);
  }

  void deleteGame(String game) {
    games?.remove(game);
  }

  void addEvent(String eventId) {
    events ??= [];
    events!.add(eventId);
  }

  void removeEvent(String eventId) {
    events?.remove(eventId);
  }
}
