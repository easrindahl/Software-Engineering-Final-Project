import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarViewModel extends ChangeNotifier {
  DateTime today = DateTime.now();
  DateTime focusedDay = DateTime.now();

  List<Map<String, dynamic>> eventsForSelectedDay = [];
  bool isLoadingEvents = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void setSelectedDay(DateTime selectedDay) {
    today = selectedDay;
    focusedDay = selectedDay;
    notifyListeners();
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

  Future<void> loadEventsForDay(DateTime day) async {
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
        loadEventsForDay(day);
      });
      return;
    }
    isLoadingEvents = true;
    eventsForSelectedDay = [];
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
      // Use local-midnight boundaries for the selected day to match the
      // user's local calendar expectations. Constructing a new DateTime
      // from year/month/day produces a local midnight.
      final DateTime selectedDayStart = DateTime(day.year, day.month, day.day);
      final DateTime tomorrowStart = selectedDayStart.add(
        const Duration(days: 1),
      );

      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      final QuerySnapshot snapshot = await _firestore
          .collection('Events')
          .where('attendees', arrayContains: currentUserId.toString())
          .get();

      // Filter date range locally
      // Use a for-loop to avoid concurrent modification errors
      final List<Map<String, dynamic>> loaded = [];
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(
          doc.data() as Map<String, dynamic>,
        );
        final eventTime = data['EventDateAndTime'];
        // Convert various stored formats to a local DateTime for comparison
        DateTime? eventDateTime;
        if (eventTime is DateTime) {
          eventDateTime = eventTime.isUtc ? eventTime.toLocal() : eventTime;
        } else if (eventTime is Timestamp) {
          eventDateTime = eventTime.toDate().toLocal();
        } else if (eventTime is String) {
          final parsed = DateTime.tryParse(eventTime);
          if (parsed != null)
            eventDateTime = parsed.isUtc ? parsed.toLocal() : parsed;
        } else {
          // Unknown format: skip this event rather than crashing
          debugPrint(
            '    ❌ Skipped: Unknown EventDateAndTime type (${eventTime.runtimeType})',
          );
          continue;
        }

        if (eventDateTime != null) {
          // include events that are at or after the start and strictly before the next day
          final bool isInRange =
              (eventDateTime.isAtSameMomentAs(selectedDayStart) ||
                  eventDateTime.isAfter(selectedDayStart)) &&
              eventDateTime.isBefore(tomorrowStart);
          debugPrint(
            '    DateTime check: $isInRange (event: ${eventDateTime.toIso8601String()}, start: ${selectedDayStart.toIso8601String()}, end: ${tomorrowStart.toIso8601String()})',
          );

          if (isInRange) {
            data['__docID'] = doc.id;

            // compute a user-friendly time string for the view to consume
            String timeStr = '';
            try {
              timeStr = _formatTime12Hour(eventDateTime);
            } catch (_) {
              timeStr = '';
            }
            data['timeStr'] = timeStr;
            loaded.add(data);
          }
        } else {
          debugPrint('    ❌ Skipped: EventDateAndTime could not be parsed');
        }
      }

      eventsForSelectedDay = loaded;
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading events: $e');
      eventsForSelectedDay = [];
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
}
