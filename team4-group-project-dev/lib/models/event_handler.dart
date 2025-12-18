//models that contain class data and types for app.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'poll_handler.dart';

class EventModel {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String EventId;
  String Title;
  // Keep a single DateTime in the model (convert to/from Timestamp for Firestore)
  DateTime EventDateAndTime;
  String EventLocation;

  String Description;
  List<PollModel>? Polls;
  GeoPoint? EventGeoPoint;
  List<String>? Attendees;

  EventModel({
    required this.EventId,
    required this.Title,
    required this.EventDateAndTime,
    this.Description = '',
    this.EventLocation = '',
    this.Polls,
    this.EventGeoPoint,
    this.Attendees,
  });

  factory EventModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      EventId: doc.id,
      Title: data['Title'] ?? '',
      // Normalize stored timestamp to a Dart local DateTime
      EventDateAndTime: () {
        final raw = data['EventDateAndTime'];
        if (raw is Timestamp) return raw.toDate().toLocal();
        if (raw is DateTime) return raw.isUtc ? raw.toLocal() : raw;
        if (raw is String) {
          final parsed = DateTime.tryParse(raw);
          if (parsed != null) return parsed.isUtc ? parsed.toLocal() : parsed;
        }
        return DateTime.now();
      }(),
      Description: data['Description'] ?? '',
      EventLocation: data['EventLocation'] ?? '',
      //will be List<Polls> when implimented
      Polls: List<PollModel>.from(data['Polls'] ?? {}),
      EventGeoPoint: data['EventGeoPoint'],

      //events parsing to be added later
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'EventId': EventId,
      'Title': Title,
      // Store as Firestore Timestamp (UTC instant) for consistent querying
      'EventDateAndTime': Timestamp.fromDate(EventDateAndTime.toUtc()),
      'Description': Description,
      'EventLocation': EventLocation,
      'Polls': Polls,
      'EventGeoPoint': EventGeoPoint,
    };

    return map;
  }

  //from map function for events
  factory EventModel.fromMap(Map<String, dynamic> data) {
    return EventModel(
      EventId: data['EventId'] ?? '',
      Title: data['Title'] ?? '',
      EventDateAndTime: () {
        final raw = data['EventDateAndTime'] ?? data['EventDate'];
        if (raw is Timestamp) return raw.toDate().toLocal();
        if (raw is DateTime) return raw.isUtc ? raw.toLocal() : raw;
        if (raw is String) {
          final parsed = DateTime.tryParse(raw);
          if (parsed != null) return parsed.isUtc ? parsed.toLocal() : parsed;
        }
        return DateTime.now();
      }(),
      Description: data['Description'] ?? '',
      EventLocation: data['EventLocation'] ?? '',
      Polls: List<PollModel>.from(data['Polls'] ?? {}),
      EventGeoPoint: data['EventGeoPoint'],
    );
  }

  //create event function

  static Future<void> CreateEvent(
    String Title,
    DateTime EventDateAndTime,
    String Description,
    String EventLocation,
    List<Map<String, dynamic>> Polls,
    List<String> Attendees,
  ) async {
    final collectionRef = _firestore.collection('Events');
    final batch = _firestore.batch();

    // create a new doc reference so we can use the generated id
    final newDoc = collectionRef.doc();
    // Resolve geocoding (may return multiple locations) and convert to a
    // Firestore GeoPoint. We must await the geocoding call here so we don't
    // store a Future in the document (which caused the "invalid argument:
    // instance of Future<List<Location>>" error).
    GeoPoint? geoPoint;
    try {
      final locations = await locationFromAddress(EventLocation);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        geoPoint = GeoPoint(loc.latitude, loc.longitude);
      }
    } catch (e) {
      // If geocoding fails, leave geoPoint null and continue — we don't want
      // the whole create operation to fail for a missing geo lookup.
      if (kDebugMode) print('Geocoding failed: $e');
      geoPoint = null;
    }

    final data = {
      'EventId': newDoc.id,
      'Title': Title,
      'EventDateAndTime': Timestamp.fromDate(EventDateAndTime),
      'Description': Description,
      'EventLocation': EventLocation,
      'Polls': Polls,
      'createdAt': FieldValue.serverTimestamp(),
      'EventGeoPoint': geoPoint,
      'attendees': Attendees,
    };

    batch.set(newDoc, data);
    try {
      await batch.commit();
    } catch (e) {
      print('Error creating event: $e');
      rethrow;
    }
  }

  getTitle() {
    return Title;
  }

  getDescription() {
    return Description;
  }

  getEventDate() {
    return EventDateAndTime;
  }

  getEventLocation() {
    return EventLocation;
  }

  getPolls() {
    return Polls;
  }

  getAttendees() {
    return Attendees;
  }

  getGeoPoint() {
    return EventGeoPoint;
  }
}
