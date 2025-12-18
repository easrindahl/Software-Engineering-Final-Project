import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

//? location package previously used for geolocation in the calendar view.
//? Currently unused because event fetching is performed in the ViewModel; keep the import
//? commented for future use or remove if not needed.
// import 'package:location/location.dart';

import 'package:provider/provider.dart';
import 'package:team4_group_project/viewmodels/calendar_viewmodel.dart';
import 'package:team4_group_project/views/event_view.dart';

// CalendarView allows players to view a calendar with events fetched from Firestore.
// When a user selects a day, it shows all events happening on that date
class CalendarView extends StatefulWidget {
  final String title;
  const CalendarView({super.key, required this.title});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  bool _hasLoaded = false;
  bool _calendarExpanded = true;

  @override
  void initState() {
    super.initState();
    // moved to didChangeDependencies to use Provider
  }

  void _onDaySelected(DateTime selectedDay, DateTime newFocusedDay) {
    final vm = context.read<CalendarViewModel>();
    vm.setSelectedDay(selectedDay);
    vm.loadEventsForDay(selectedDay);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      final vm = context.read<CalendarViewModel>();
      // Schedule the load after the first frame to avoid calling
      // notifyListeners() during the build phase (which causes errors).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.loadEventsForDay(vm.today);
      });
      _hasLoaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Events Calendar")),
      body: content(),
    );
  }

  Widget content() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Consumer<CalendarViewModel>(
            builder: (context, vm, _) {
              return Text(
                "Selected Day: ${vm.today.toString().split(' ')[0]}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
                    // Calendar Toggle Header
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: IconButton(
                icon: Icon(_calendarExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _calendarExpanded = !_calendarExpanded;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _calendarExpanded = !_calendarExpanded;
                });
              },
            ),
          ),
          
          // Collapsible Calendar
          if (_calendarExpanded) ...[
            const SizedBox(height: 10),
            Consumer<CalendarViewModel>(
              builder: (context, vm, _) {
                return TableCalendar(
                  locale: 'en_US',
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  availableGestures: AvailableGestures.all,
                  selectedDayPredicate: (day) => isSameDay(day, vm.today),
                  focusedDay: vm.focusedDay,
                  firstDay: DateTime.utc(2015, 10, 22),
                  lastDay: DateTime.utc(2030, 10, 22),
                  onDaySelected: _onDaySelected,
                );
              },
            ),
            const SizedBox(height: 20),
          ] else ...[
            const SizedBox(height: 20),
          ],
          Consumer<CalendarViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoadingEvents) return const CircularProgressIndicator();
              if (vm.eventsForSelectedDay.isEmpty)
                return const Text("No events for this day.");
              return Expanded(
                child: ListView.builder(
                  itemCount: vm.eventsForSelectedDay.length,
                  itemBuilder: (context, index) {
                    final event = vm.eventsForSelectedDay[index];
                    final timeStr = event['timeStr'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        title: Text(event['Title'] ?? 'Untitled Event'),
                        subtitle: Text(
                          '${event['Description'] ?? ''}\n'
                          '${event['EventLocation'] ?? ''}\n'
                          '$timeStr',
                        ),
                        isThreeLine: true,
                        onTap: () {
                          // Show the event detail dialog when tapped.
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => EventViewDialog(event: event),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
