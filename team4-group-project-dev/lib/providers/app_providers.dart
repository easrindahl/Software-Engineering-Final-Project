import 'package:provider/provider.dart';
import 'package:team4_group_project/viewmodels/home_viewmodel.dart';
import 'package:team4_group_project/viewmodels/account_viewmodel.dart';
import 'package:team4_group_project/viewmodels/event_viewModel.dart';
import 'package:team4_group_project/viewmodels/settings_viewmodel.dart';
import 'package:team4_group_project/viewmodels/calendar_viewmodel.dart';
import 'package:team4_group_project/viewmodels/create_event_viewmodel.dart';
import 'package:team4_group_project/viewmodels/user_home_viewmodel.dart';
import 'package:team4_group_project/viewmodels/poll_viewmodel.dart';
import 'package:team4_group_project/viewmodels/theme_viewmodel.dart';


/// Central place to declare app-level providers.
/// Mirrors the sample project's `providers/` pattern.
final appProviders = [
  ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()),
  ChangeNotifierProvider<AccountViewModel>(create: (_) => AccountViewModel()),
  ChangeNotifierProvider<EventViewModel>(create: (_) => EventViewModel()),
  ChangeNotifierProvider<SettingsViewModel>(create: (_) => SettingsViewModel()),
  ChangeNotifierProvider<CalendarViewModel>(create: (_) => CalendarViewModel()),
  ChangeNotifierProvider<CreateEventViewModel>(create: (_) => CreateEventViewModel()),
  ChangeNotifierProvider<UserHomeViewModel>(create: (_) => UserHomeViewModel()),
  ChangeNotifierProvider<PollViewModel>(create: (_) => PollViewModel()),
  ChangeNotifierProvider<ThemeViewModel>(create: (_) => ThemeViewModel()),
];
