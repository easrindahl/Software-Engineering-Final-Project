import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team4_group_project/models/event_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';

Future<List<String>> _fetchAddressSuggestions(String input) async {
  if (input.isEmpty) return [];

  // Build the Nominatim URL
  final url = Uri.parse(
    "https://nominatim.openstreetmap.org/search?q=$input&format=json&addressdetails=1&limit=5",
  );

  final response = await http.get(
    url,
    headers: {
      "User-Agent": "Team4GroupProjectApp", // Nominatim requires a User-Agent
    },
  );

  if (response.statusCode != 200) return [];

  final data = jsonDecode(response.body) as List;

  // Extract display_name from each result
  return data.map<String>((item) => item['display_name'] as String).toList();
}

class CreateEventView extends StatefulWidget {
  final String title;
  const CreateEventView({super.key, required this.title});

  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _date = ''; // simple date string for now
  TimeOfDay? _time;
  String _location = '';
  String _description = '';
  bool _loading = false;
  List<String> _attendees = [];

  //! AI-generated code: Poll creation fields
  final List<Map<String, dynamic>> _polls = [];
  final _pollNameController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _pollNameController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  DateTime? _selectedDate; // add this at the top if not already

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(3000),
    );
    if (result != null) setState(() => _date = result.toIso8601String());
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (result != null) setState(() => _time = result);
  }

  //! AI-generated code: Show dialog to add a poll
  void _showAddPollDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Game Night Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _pollNameController,
                  decoration: const InputDecoration(
                    labelText:
                        'Poll Question (e.g., "What game should we play?")',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Options:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._optionControllers.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Option ${idx + 1}',
                            ),
                          ),
                        ),
                        if (_optionControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () {
                              setDialogState(() {
                                controller.dispose();
                                _optionControllers.removeAt(idx);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }).toList(),
                TextButton.icon(
                  onPressed: () {
                    setDialogState(() {
                      _optionControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _pollNameController.clear();
                _optionControllers.forEach((c) => c.clear());
                // Do not dispose controllers before the dialog is removed from the tree.
                // Popping first prevents disposing a controller that a TextField still depends on.
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  while (_optionControllers.length > 2) {
                    final removed = _optionControllers.removeLast();
                    removed.dispose();
                  }
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final pollName = _pollNameController.text.trim();
                final options = _optionControllers
                    .map((c) => c.text.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                if (pollName.isNotEmpty && options.length >= 2) {
                  setState(() {
                    _polls.add({
                      'PollId': DateTime.now().millisecondsSinceEpoch
                          .toString(),
                      'PollName': pollName,
                      'Options': options,
                      'multipleChoices': false,
                      'votes': {},
                    });
                  });
                  _pollNameController.clear();
                  _optionControllers.forEach((c) => c.clear());
                  Navigator.of(context).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    while (_optionControllers.length > 2) {
                      final removed = _optionControllers.removeLast();
                      removed.dispose();
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a question and at least 2 options',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Add Poll'),
            ),
          ],
        ),
      ),
    );
  }

  // AI-generated code: Remove a poll from the list
  void _removePoll(int index) {
    setState(() {
      _polls.removeAt(index);
    });
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);
    try {
      DateTime eventDateTime;
      if (_date.isNotEmpty && _time != null) {
        final parsedDate = DateTime.parse(_date);
        eventDateTime = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          _time!.hour,
          _time!.minute,
        );
      } else {
        eventDateTime = DateTime.now();
      }

      await EventModel.CreateEvent(
        _title,
        eventDateTime,
        _description,
        _location,
        _polls,
        _attendees,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event created')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating event: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                onSaved: (v) => _title = v!.trim(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(_date.isNotEmpty ? _date : 'No date selected'),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Pick Date'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _time != null
                          ? 'Time: ${_time!.format(context)}'
                          : 'No time selected',
                    ),
                  ),
                  TextButton(
                    onPressed: _pickTime,
                    child: const Text('Pick Time'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TypeAheadField<String>(
                controller: TextEditingController(text: _location),
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Location'),
                    onChanged: (value) => _location = value,
                  );
                },
                suggestionsCallback: (pattern) async {
                  return await _fetchAddressSuggestions(pattern);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(title: Text(suggestion));
                },
                onSelected: (suggestion) {
                  setState(() {
                    _location = suggestion;
                  });
                },
              ),

              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              //! AI-generated code: Poll management section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Game Night Polls (${_polls.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: _showAddPollDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Poll'),
                  ),
                ],
              ),
              if (_polls.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._polls.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var poll = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(poll['PollName'] as String),
                      subtitle: Text(
                        '${(poll['Options'] as List).length} options',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removePoll(idx),
                      ),
                    ),
                  );
                }).toList(),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _createEvent,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Create Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
