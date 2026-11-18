import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Supported locales for Evora-Workers (English & Hindi).
class SupportedWorkerLocales {
  SupportedWorkerLocales._();

  static const Locale english = Locale('en');
  static const Locale hindi = Locale('hi');

  static const List<Locale> all = [english, hindi];

  static Locale fromCode(String? code) {
    if (code == 'hi') return hindi;
    return english;
  }
}

/// Immutable state holding the active locale and whether the user
/// has completed the first-launch language picker.
class LocaleState {
  final Locale locale;
  final bool hasSelectedLanguage;

  const LocaleState({
    required this.locale,
    required this.hasSelectedLanguage,
  });

  bool get isHindi => locale.languageCode == 'hi';

  LocaleState copyWith({
    Locale? locale,
    bool? hasSelectedLanguage,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      hasSelectedLanguage: hasSelectedLanguage ?? this.hasSelectedLanguage,
    );
  }
}

/// Manages language selection on first install and runtime language switching.
class LocaleNotifier extends StateNotifier<LocaleState> {
  LocaleNotifier({
    required SharedPreferences prefs,
  })  : _prefs = prefs,
        super(
          LocaleState(
            locale: SupportedWorkerLocales.fromCode(
              prefs.getString(AppConstants.prefLocaleCode),
            ),
            hasSelectedLanguage:
                prefs.getBool(AppConstants.prefHasSelectedLanguage) ?? false,
          ),
        );

  final SharedPreferences _prefs;

  /// Persists the chosen language and marks first-launch selection complete.
  Future<void> selectLanguage(Locale locale) async {
    final normalized = SupportedWorkerLocales.fromCode(locale.languageCode);
    state = state.copyWith(
      locale: normalized,
      hasSelectedLanguage: true,
    );
    await _prefs.setString(AppConstants.prefLocaleCode, normalized.languageCode);
    await _prefs.setBool(AppConstants.prefHasSelectedLanguage, true);
  }

  /// Toggles between English and Hindi at runtime.
  Future<void> toggleLanguage() async {
    final next = state.isHindi
        ? SupportedWorkerLocales.english
        : SupportedWorkerLocales.hindi;
    await selectLanguage(next);
  }
}

/// Must be overridden at app startup with an initialized [SharedPreferences] instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope.',
  );
});

final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs: prefs);
});
