import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_state.dart';

/// Currency symbol from settings, falling back to '$' while loading.
/// Uses `watch` so widgets rebuild when the symbol changes.
String currencySymbolOf(BuildContext context) {
  final state = context.watch<SettingsBloc>().state;
  return state is SettingsLoaded ? state.settings.currencySymbol : '\$';
}
