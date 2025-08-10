import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/features/home/home_screen.dart';
import 'package:greek_quiz/features/settings/app_settings.dart';
import 'package:greek_quiz/features/settings/settings_provider.dart';
import 'package:greek_quiz/l10n/app_localizations.dart';
import 'package:audio_session/audio_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());
  await session.setActive(true);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(settingsProvider.select((s) => s.appTheme));
    final interfaceLanguageCode = ref.watch(settingsProvider.select((s) => s.interfaceLanguage));

    final themeMode = switch (appTheme) {
      AppTheme.light => ThemeMode.light,
      AppTheme.dark => ThemeMode.dark,
      AppTheme.system => ThemeMode.system,
    };

    final locale = (interfaceLanguageCode == 'system') ? null : Locale(interfaceLanguageCode);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Greek Quiz',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}