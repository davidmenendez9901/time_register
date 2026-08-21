import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_state.dart';

/// Currency symbol from settings, falling back to '$' while loading.
String currencySymbolOf(BuildContext context) {
  return context.select<SettingsBloc, String>((bloc) {
    final state = bloc.state;
    return state is SettingsLoaded ? state.settings.currencySymbol : '\$';
  });
}
