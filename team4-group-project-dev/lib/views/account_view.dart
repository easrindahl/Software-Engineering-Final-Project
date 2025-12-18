import 'package:flutter/material.dart';
import 'package:team4_group_project/viewmodels/account_viewmodel.dart';
import 'package:provider/provider.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger a one-time load of the user page when the widget is inserted into the tree.
    if (!_hasLoaded) {
      _hasLoaded = true;
      // Schedule the async call after the current frame to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AccountViewModel>().getUserPage('');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Account Settings',
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.user == null
          ? const Center(child: Text('No user data'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: vm.user!.photoUrl.isNotEmpty
                          ? NetworkImage(vm.user!.photoUrl)
                          : null,
                      child: vm.user!.photoUrl.isEmpty
                          ? Text(
                              vm.user!.name.isNotEmpty
                                  ? vm.user!.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Name: ${vm.user!.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (vm.user!.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Bio: ${vm.user!.bio}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  if (vm.user!.phone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Phone: ${vm.user!.phone}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  if (vm.user!.tools != null && vm.user!.tools!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Tools:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: vm.user!.tools!
                          .map((tool) => Chip(label: Text(tool)))
                          .toList(),
                    ),
                  ],
                  if (vm.user!.games != null && vm.user!.games!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Games:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: vm.user!.games!
                          .map((game) => Chip(label: Text(game)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
