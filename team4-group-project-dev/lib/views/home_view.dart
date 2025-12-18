import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:team4_group_project/viewmodels/home_viewmodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:team4_group_project/views/event_view.dart';
import 'package:team4_group_project/theme_toggle.dart';

// UI moved into a `views/` file to match the sample structure.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // non-blocking init hook on the HomeViewModel
      context.read<HomeViewModel>().init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // delegate sign-out to viewmodel
              context.read<HomeViewModel>().signOut();
            },
            tooltip: 'Sign Out',
          ),

          theme_switch_widget(), //Adds theme switch next to the sign out button on the home page.
        ],
      ),
      body: Column(
        children: [
          Consumer<HomeViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return Expanded(
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              if (vm.error != null) {
                return Expanded(
                  child: Center(child: Text('Error: ${vm.error}')),
                );
              }
              if (!vm.serviceEnabled) {
                return Expanded(
                  child: const Center(
                    child: Text('Location services are disabled.'),
                  ),
                );
              }
              if (vm.permission == LocationPermission.denied ||
                  vm.permission == LocationPermission.deniedForever) {
                return Expanded(
                  child: const Center(
                    child: Text('Location permissions are denied.'),
                  ),
                );
              }
              if (vm.eventsFromToday.isEmpty) {
                return Expanded(
                  child: const Center(child: Text('No events available.')),
                );
              }
              return Expanded(
                child: ListView.builder(
                  itemCount: vm.eventsFromToday.length,
                  itemBuilder: (context, index) {
                    final event = vm.eventsFromToday[index];
                    final timeStr = event['EventDateAndTime'] ?? '';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Preferred Search Distance:'),
              ),
              DropdownButton<searchDistances>(
                value: context.watch<HomeViewModel>().preferredDistance,
                items: const [
                  DropdownMenuItem(
                    value: searchDistances.none,
                    child: Text('None'),
                  ),
                  DropdownMenuItem(
                    value: searchDistances.km5,
                    child: Text('5 km'),
                  ),
                  DropdownMenuItem(
                    value: searchDistances.km10,
                    child: Text('10 km'),
                  ),
                  DropdownMenuItem(
                    value: searchDistances.km20,
                    child: Text('20 km'),
                  ),
                  DropdownMenuItem(
                    value: searchDistances.km50,
                    child: Text('50 km'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    context.read<HomeViewModel>().setPreferredDistance(value);
                  }
                },
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('create_event'),
        onPressed: () {
          Navigator.pushNamed(context, '/createEvent');
        },
        tooltip: 'Create Event',
        child: const Icon(Icons.add),
      ),
    );
  }
}
