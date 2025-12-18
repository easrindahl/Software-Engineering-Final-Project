import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
//import 'package:geocoding/geocoding.dart';

enum searchDistances { none, km5, km10, km20, km50 }

/// Simple HomeViewModel demonstrating MVVM with ChangeNotifier.
/// Keeps auth/sign-out logic out of the UI.
class HomeViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  DateTime today = DateTime.now();
  DateTime focusedDay = DateTime.now();

  List<Map<String, dynamic>> eventsFromToday = [];
  bool isLoadingEvents = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool serviceEnabled = false;
  LocationPermission permission = LocationPermission.denied;

  searchDistances preferredDistance = searchDistances.km10;

  Future<void> signOut() async {
    _setLoading(true);
    _error = null;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // format DateTime into a 12-hour time string (e.g., "3:05 PM")
  String _formatTime12Hour(DateTime dt) {
    final int hour = dt.hour;
    final int minute = dt.minute;
    final String minuteStr = minute.toString().padLeft(2, '0');
    final bool isPm = hour >= 12;
    final int hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final String ampm = isPm ? 'PM' : 'AM';
    return '$hour12:$minuteStr $ampm';
  }

  /// Optional initialization hook for the Home view.
  /// Use this to load any data needed by the Home screen when it appears.
  Future<void> init() async {
    // Placeholder: load initial data here if needed.
    refresh();
  }

  Future<void> refresh() async {
    // Establish geolocation services
    // Check service enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }
    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    // Ensure we yield to the event loop so this method never triggers
    // synchronous notifyListeners during widget build. A short zero-delay
    // gives the framework time to finish the current build pass.
    await Future<void>.delayed(Duration.zero);
    // If this is called during the framework's build phase it may call
    // notifyListeners() synchronously which causes the "setState() or
    // markNeedsBuild() called during build" exception. If we're in the
    // build phase, schedule this load to run after the current frame.
    // If we're currently in any scheduler phase other than idle, defer the
    // load to after the current frame to avoid calling notifyListeners
    // synchronously during widget build/flush phases.
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        refresh();
      });
      return;
    }
    isLoadingEvents = true;
    eventsFromToday = [];
    // Defer the initial notification until after the current frame to avoid
    // calling notifyListeners() while widgets are being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        notifyListeners();
      } catch (_) {
        // ignore errors from notify during teardown
      }
    });

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('Events')
          .where('EventDateAndTime', isGreaterThanOrEqualTo: DateTime.now())
          .get();
      eventsFromToday = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Optionally format time fields here
        if (data.containsKey('startTime')) {
          final DateTime startDt = DateTime.parse(data['startTime']);
          data['formattedStartTime'] = _formatTime12Hour(startDt);
        }
        if (data.containsKey('endTime')) {
          final DateTime endDt = DateTime.parse(data['endTime']);
          data['formattedEndTime'] = _formatTime12Hour(endDt);
        }
        return data;
      }).toList();
      // Filter events based on preferred distance
      if (preferredDistance != searchDistances.none) {
        for (var event in eventsFromToday) {
          GeoPoint eventLocation = event['EventGeoPoint'];
          double eventLat = eventLocation.latitude;
          double eventLon = eventLocation.longitude;
          Position userPosition = await Geolocator.getCurrentPosition();
          double distanceInMeters = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            eventLat,
            eventLon,
          );
          double distanceInKm = distanceInMeters / 1000.0;
          bool withinPreferredDistance = false;
          switch (preferredDistance) {
            case searchDistances.none: // Redundant but flutter is cringe
              withinPreferredDistance = true;
              break;
            case searchDistances.km5:
              withinPreferredDistance = distanceInKm <= 5.0;
              break;
            case searchDistances.km10:
              withinPreferredDistance = distanceInKm <= 10.0;
              break;
            case searchDistances.km20:
              withinPreferredDistance = distanceInKm <= 20.0;
              break;
            case searchDistances.km50:
              withinPreferredDistance = distanceInKm <= 50.0;
              break;
          }
          if (!withinPreferredDistance) {
            eventsFromToday.remove(event);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading events: $e');
      eventsFromToday = [];
    } finally {
      isLoadingEvents = false;
      // Always schedule notifications to run after the current frame so we
      // never call notifyListeners() synchronously during a widget build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          notifyListeners();
        } catch (_) {
          // ignore errors if the framework is tearing down
        }
      });
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void setPreferredDistance(searchDistances newPreferredDistance) {
    preferredDistance = newPreferredDistance;
    refresh();
  }
}
