import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:team4_group_project/viewmodels/theme_viewmodel.dart';


class theme_switch_widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme_provider = Provider.of<ThemeViewModel>(context);

    return Switch.adaptive(
      value: theme_provider.is_dark_mode,
      onChanged: (value) {
        final provider = Provider.of<ThemeViewModel>(context, listen: false);
        provider.toggle_theme(value);
      },
    );
  }
}