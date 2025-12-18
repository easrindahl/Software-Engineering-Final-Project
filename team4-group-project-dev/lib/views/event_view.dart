import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:team4_group_project/viewmodels/event_viewModel.dart';
import 'package:team4_group_project/viewmodels/poll_viewmodel.dart';
import 'package:team4_group_project/models/user_service.dart' show getCurrentUserId;
import 'package:team4_group_project/models/remote_services.dart';

// simple dialog that displays details for a single event
class EventViewDialog extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventViewDialog({super.key, required this.event});

  @override
  State<EventViewDialog> createState() => _EventViewDialogState();
}

class _EventViewDialogState extends State<EventViewDialog> {
  late Set<String> _attendees;
  bool _isProcessing = false;
  String? _error;
  String? _currentUserId;
  Map<String, String> _attendeeNames = {};
  bool _loadingNames = false;
  // Maintain a mutable copy of polls to reflect vote changes immediately
  List<Map<String, dynamic>> _polls = [];

  @override
  void initState() {
    super.initState();
    final raw = widget.event['attendees'] as List<dynamic>?;
    _attendees = raw != null
        ? raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toSet()
        : <String>{};
    // copy polls list safely
    final pollsRaw = widget.event['Polls'] as List<dynamic>?;
    _polls = pollsRaw != null
      ? pollsRaw.map((p) => Map<String, dynamic>.from(p as Map)).toList()
      : <Map<String, dynamic>>[];
    // load current user id for button label/logic
    getCurrentUserId().then((id) {
      if (mounted) setState(() => _currentUserId = id);
    });
    // load attendee names
    _loadAttendeeNames();
  }

  Future<void> _loadAttendeeNames() async {
    if (_attendees.isEmpty) return;
    setState(() => _loadingNames = true);
    try {
      final remoteServices = RemoteServices();
      // Provide immediate fallbacks so UI never shows Loading... 
      final names = <String, String>{
        for (final id in _attendees)
          id: _attendeeNames[id] ?? id.substring(0, id.length >= 6 ? 6 : id.length)
      };
      // Fetch all users concurrently for speed
      final futures = _attendees.map((userId) async {
        final user = await remoteServices.getUserData(userId);
        if (user != null && user.name.trim().isNotEmpty) {
          names[userId] = user.name.trim();
        }
      });
      await Future.wait(futures);
      if (mounted) {
        setState(() {
          _attendeeNames = names;
          _loadingNames = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingNames = false);
      }
    }
  }

  Future<void> _toggleRsvp() async {
    final eventId = widget.event['__docID'] as String? ?? widget.event['EventId'] as String? ?? '';
    if (eventId.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final vm = context.read<EventViewModel>();
      final currentUserId = _currentUserId ?? await getCurrentUserId();
      if (currentUserId.isEmpty) {
        setState(() => _error = 'Not signed in');
        return;
      }
      final success = await vm.rsvpToEvent(eventId);
      if (success) {
        setState(() {
          if (_attendees.contains(currentUserId)) {
            _attendees.remove(currentUserId);
            _attendeeNames.remove(currentUserId);
          } else {
            _attendees.add(currentUserId);
            // Load the name for the newly added attendee
            _loadAttendeeNames();
          }
          // Propagate changes to the original event map so reopening shows updated list
          widget.event['attendees'] = _attendees.toList();
        });
      } else {
        setState(() => _error = vm.error ?? 'Failed to update RSVP');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final title = event['Title'] as String? ?? 'Untitled Event';
    final description = event['Description'] as String? ?? '';
    final location = event['EventLocation'] as String? ?? '';
    final date = event['EventDate'] as String? ?? '';
    final timeStr = event['timeStr'] as String? ?? '';

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              //! AI-generated code: Wrapped content in Expanded + SingleChildScrollView to handle overflow
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (date.isNotEmpty || timeStr.isNotEmpty)
                        Row(
                          children: [
                            if (date.isNotEmpty) Text(date),
                            if (date.isNotEmpty && timeStr.isNotEmpty)
                              const SizedBox(width: 8),
                            if (timeStr.isNotEmpty) Text(timeStr),
                          ],
                        ),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Expanded(child: Text(location)),
                          ],
                        ),
                      ],
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Attendees section
                      Row(
                        children: [
                          const Icon(Icons.people, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Attendees: ${_attendees.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      if (_attendees.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        if (_loadingNames)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          )
                        else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _attendees.map((userId) {
                                  final raw = _attendeeNames[userId];
                                  final displayName = (raw != null && raw.trim().isNotEmpty)
                                      ? raw.trim()
                                      : userId.substring(0, userId.length >= 6 ? 6 : userId.length);
                                  return Chip(
                                    avatar: CircleAvatar(
                                      child: Text(
                                        displayName[0].toUpperCase(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    label: Text(displayName),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                      ],
                      //! AI-generated code: Display polls section
                      if (_polls.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.poll, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Game Night Polls',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._polls.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final poll = entry.value;
                          return _PollWidget(
                            poll: poll,
                            eventId: widget.event['__docID'] as String? ?? widget.event['EventId'] as String? ?? '',
                            currentUserId: _currentUserId,
                            onPollUpdated: (updated) {
                              setState(() {
                                _polls[idx] = updated;
                                // also update original event map so external references (if reused) get latest
                                final originalPolls = widget.event['Polls'] as List<dynamic>?;
                                if (originalPolls != null && idx < originalPolls.length) {
                                  originalPolls[idx] = updated;
                                }
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _toggleRsvp,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text((_currentUserId != null && _attendees.contains(_currentUserId))
                            ? 'Cancel RSVP'
                            : 'RSVP'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//! AI-generated code: Widget to display individual poll with voting and results
class _PollWidget extends StatefulWidget {
  final Map<String, dynamic> poll;
  final String eventId;
  final String? currentUserId;
  final ValueChanged<Map<String, dynamic>>? onPollUpdated;

  const _PollWidget({
    required this.poll,
    required this.eventId,
    this.currentUserId,
    this.onPollUpdated,
  });

  @override
  State<_PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<_PollWidget> {
  bool _isVoting = false;
  String? _localUserVote;
  Map<String, String>? _localVotes;

  @override
  void initState() {
    super.initState();
    _localVotes = Map<String, String>.from(widget.poll['votes'] ?? {});
    if (widget.currentUserId != null) {
      _localUserVote = _localVotes?[widget.currentUserId!];
    }
  }

  //! AI-generated code: Enhanced to allow removing vote by clicking same option, or changing vote
  Future<void> _handleVote(String option) async {
    if (widget.currentUserId == null || _isVoting) return;
    
    setState(() => _isVoting = true);
    
    try {
      final pollViewModel = PollViewModel();
      bool success;
      
      // If clicking the same option they already voted for, remove their vote
      if (_localUserVote == option) {
        success = await pollViewModel.removeVote(
          widget.eventId,
          widget.poll['PollId'] as String,
        );
        
        if (success && mounted) {
          setState(() {
            _localVotes?.remove(widget.currentUserId!);
            _localUserVote = null;
          });
          // propagate update
          widget.onPollUpdated?.call({
            ...widget.poll,
            'votes': Map<String, String>.from(_localVotes ?? {}),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vote removed')),
          );
        }
      } else {
        // Otherwise, vote for the selected option (or change vote)
        success = await pollViewModel.voteOnPoll(
          widget.eventId,
          widget.poll['PollId'] as String,
          option,
        );
        
        if (success && mounted) {
          setState(() {
            _localVotes ??= {};
            _localVotes![widget.currentUserId!] = option;
            _localUserVote = option;
          });
          widget.onPollUpdated?.call({
            ...widget.poll,
            'votes': Map<String, String>.from(_localVotes ?? {}),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_localUserVote == null ? 'Vote submitted!' : 'Vote changed!')),
          );
        }
      }
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pollViewModel.error ?? 'Failed to update vote')),
        );
      }
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }

  Map<String, int> _calculateVoteCounts() {
    final options = List<String>.from(widget.poll['Options'] ?? []);
    final votes = _localVotes ?? {};
    
    Map<String, int> voteCounts = {};
    for (var option in options) {
      voteCounts[option] = 0;
    }
    votes.forEach((userId, option) {
      if (voteCounts.containsKey(option)) {
        voteCounts[option] = voteCounts[option]! + 1;
      }
    });
    return voteCounts;
  }

  @override
  Widget build(BuildContext context) {
    final pollName = widget.poll['PollName'] as String? ?? 'Unnamed Poll';
    final options = List<String>.from(widget.poll['Options'] ?? []);
    final hasVoted = _localUserVote != null;
    final voteCounts = _calculateVoteCounts();
    final totalVotes = _localVotes?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.poll_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pollName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$totalVotes ${totalVotes == 1 ? "vote" : "votes"}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            //! AI-generated code: Show results with interactive voting - users can click to vote/change/remove
            if (widget.currentUserId != null) ...[
              // Show results with clickable options
              ...options.map((option) {
                final count = voteCounts[option] ?? 0;
                final percentage = totalVotes > 0 ? (count / totalVotes * 100) : 0.0;
                final isUserChoice = _localUserVote == option;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: _isVoting ? null : () => _handleVote(option),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isUserChoice ? Colors.green : Colors.grey.shade300,
                          width: isUserChoice ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isUserChoice ? Colors.green.withOpacity(0.1) : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontWeight: isUserChoice ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (isUserChoice) ...[
                                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                      const SizedBox(width: 4),
                                    ],
                                  ],
                                ),
                              ),
                              if (totalVotes > 0)
                                Text(
                                  '$count (${percentage.toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isUserChoice ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                          if (totalVotes > 0) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: count / totalVotes,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isUserChoice ? Colors.green : Colors.blue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              if (_isVoting) ...[
                const SizedBox(height: 8),
                const Center(child: CircularProgressIndicator()),
              ],
              if (hasVoted) ...[
                const SizedBox(height: 8),
                Text(
                  'Tip: Click your choice again to remove your vote, or click another option to change it',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ] else if (totalVotes > 0) ...[
              // Not logged in - show results only
              ...options.map((option) {
                final count = voteCounts[option] ?? 0;
                final percentage = totalVotes > 0 ? (count / totalVotes * 100) : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(option)),
                          Text(
                            '$count (${percentage.toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: count / totalVotes,
                        backgroundColor: Colors.grey[200],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              const Text(
                'No votes yet. Be the first to vote!',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
