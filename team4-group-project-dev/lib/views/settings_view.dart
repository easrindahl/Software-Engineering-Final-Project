import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team4_group_project/models/user_handler.dart';
import 'package:provider/provider.dart';
import 'package:team4_group_project/viewmodels/settings_viewmodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _toolController = TextEditingController();
  final TextEditingController _gameController = TextEditingController(); 
  List<String> _tools = [];
  List<String> _games = [];
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  File? _photoFile;
  var _initialized = false;
  double? _lastKnownLat;
  double? _lastKnownLng;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _toolController.dispose();
    _gameController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save(String userId) async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<SettingsViewModel>();
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newBio = _bioController.text.trim();
    final newAddress = _addressController.text.trim();

  double? lat;
  double? lng;
    if (newAddress.isNotEmpty) {
      try {
        final locations = await locationFromAddress(newAddress);
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
        }
      } catch (e) {
        // If geocoding fails, continue without coordinates; address string
        // will still be saved
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not geocode address')
          ),
        );
      }
    }

    // If it can't geocode an address but the user used the "Use current
    // Address function, prefers that 
    
    lat ??= _lastKnownLat;
    lng ??= _lastKnownLng;

    final payload = {
      'name': newName,
      'phone': newPhone,
      'bio': newBio,
      'address': newAddress,
      'tools': _tools,
      'games': _games,
    };
    if (lat != null && lng != null) {
      payload['latitude'] = lat;
      payload['longitude'] = lng;
    }

    final success = await vm.saveProfile(userId, payload);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${vm.error}')),
      );
    }
  }

  Future<void> _pickAndUploadPhoto(String userId) async {
    // Read the ViewModel before any `await` so we don't use BuildContext across async gaps.
    final vm = context.read<SettingsViewModel>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() {
      _photoFile = File(picked.path);
    });
    final url = await vm.uploadPhoto(_photoFile!, userId);
    if (!mounted) return;
    if (url != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: ${vm.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Builder(
          builder: (context) {
            final vm = context.watch<SettingsViewModel>();
            return StreamBuilder<UserModel?>(
              stream: vm.userStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text('No user data available'));
                }

                final raw = snapshot.data!;
                // Defensive: sometimes the stream may (incorrectly) emit a
                // Future<UserModel?> instead of a UserModel. Handle both.
                if (raw is Future) {
                  // Defensive fallback: if the stream accidentally emits a
                  // Future, show a simple loading indicator instead of
                  // crashing. The stream should normally emit a UserModel.
                  return const Center(child: CircularProgressIndicator());
                }

                final UserModel user = raw;
                return Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile picture + title
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: _photoFile != null
                                    ? FileImage(_photoFile!) as ImageProvider
                                    : (user.photoUrl.isNotEmpty
                                          ? NetworkImage(user.photoUrl)
                                          : null),
                                child:
                                    (user.photoUrl.isEmpty &&
                                        _photoFile == null)
                                    ? Text(
                                        user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(fontSize: 28),
                                      )
                                    : null,
                              ),
                              FloatingActionButton.small(
                                heroTag: 'pickPhoto',
                                onPressed: () => _pickAndUploadPhoto(user.id),
                                child: Consumer<SettingsViewModel>(
                                  builder: (context, vm, _) {
                                    return vm.uploadingPhoto
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.camera_alt);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Edit your profile',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your Phone Number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null) return null;
                          final t = v.trim();
                          if (t.isEmpty) return null;
                          final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
                          return digits.length < 7
                              ? 'Please enter a valid phone number'
                              : null;
                        },
                      ),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Enter your Address',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.my_location),
                            tooltip: 'Use current location',
                            onPressed: _fillAddressFromCurrentLocation,
                          ),
                        ),
                        validator: (v) => null,
                      ),
                      TextFormField(
                        controller: _bioController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your Bio',
                        ),
                        validator: (v) => null,
                      ),
                      const SizedBox(height: 12),
                      // Tools input: add a single tool at a time
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _toolController,
                              decoration: const InputDecoration(
                                labelText: 'Add tool (press + to add)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final t = _toolController.text.trim();
                              if (t.isEmpty) return;
                              if (!_tools.contains(t))
                                setState(() => _tools.add(t));
                              _toolController.clear();
                            },
                            tooltip: 'Add tool',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_tools.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          children: _tools
                              .map(
                                (tool) => Chip(
                                  label: Text(tool),
                                  onDeleted: () =>
                                      setState(() => _tools.remove(tool)),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Games input: mirrors the Tools input exactly but for games
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _gameController,
                              decoration: const InputDecoration(
                                labelText: 'Add game (press + to add)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              final t = _gameController.text.trim();
                              if (t.isEmpty) return;
                              if (!_games.contains(t)) setState(() => _games.add(t));
                              _gameController.clear();
                            },
                            tooltip: 'Add game',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_games.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          children: _games
                              .map(
                                (game) => Chip(
                                  label: Text(game),
                                  onDeleted: () =>
                                      setState(() => _games.remove(game)),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          Consumer<SettingsViewModel>(
                            builder: (context, vm, _) {
                              return ElevatedButton(
                                onPressed: vm.isLoading
                                    ? null
                                    : () => _save(user.id),
                                child: vm.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save'),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Read the ViewModel before awaiting to avoid use_build_context_synchronously
      final vm = context.read<SettingsViewModel>();
      vm
          .fetchCurrentUser()
          .then((user) {
            if (!mounted) return;
            if (user == null) return;
            setState(() {
              if (_nameController.text.isEmpty)
                _nameController.text = user.name;
              if (_phoneController.text.isEmpty)
                _phoneController.text = user.phone;
              if (_bioController.text.isEmpty) _bioController.text = user.bio;
              if (_addressController.text.isEmpty)
                _addressController.text = user.address;
              if (_tools.isEmpty) _tools = List<String>.from(user.tools ?? []);
              if (_games.isEmpty) _games = List<String>.from(user.games ?? []);
            });
          })
          .catchError((_) {
            // ignore errors here; stream builder will handle live data
          });
    }
  }

  Future<void> _fillAddressFromCurrentLocation() async {
    // Check if running on Windows where geolocator is not supported
    if (Platform.isWindows) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are not supported on Windows. Please enter address manually.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check service enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are denied')),
      );
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];
        if ((p.street ?? '').isNotEmpty) parts.add(p.street!);
        if ((p.locality ?? '').isNotEmpty) parts.add(p.locality!);
        if ((p.administrativeArea ?? '').isNotEmpty) parts.add(p.administrativeArea!);
        if ((p.postalCode ?? '').isNotEmpty) parts.add(p.postalCode!);
        if ((p.country ?? '').isNotEmpty) parts.add(p.country!);
        final addr = parts.join(', ');
        setState(() {
          _addressController.text = addr;
          _lastKnownLat = pos.latitude;
          _lastKnownLng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }
}
