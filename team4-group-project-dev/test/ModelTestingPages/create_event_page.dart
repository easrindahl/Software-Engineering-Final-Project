import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team4_group_project/models/event_handler.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _date = ''; // simple date string for now
  TimeOfDay? _time;
  String _location = '';
  String _description = '';
  bool _loading = false;

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (result != null) setState(() => _time = result);
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);
    try {
      final timestamp = _time != null
          ? Timestamp.fromDate(
              DateTime.now()
                  .toUtc()
                  .subtract(Duration(hours: 0))
                  .copyWith(hour: _time!.hour, minute: _time!.minute),
            )
          : Timestamp.now();

      await EventModel.CreateEvent(
        _title,
        _date,
        _description,
        timestamp,
        _location,
        [],
        [],
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
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a date' : null,
                onSaved: (v) => _date = v!.trim(),
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
              TextFormField(
                decoration: const InputDecoration(labelText: 'Location'),
                onSaved: (v) => _location = v?.trim() ?? '',
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                onSaved: (v) => _description = v?.trim() ?? '',
              ),
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
