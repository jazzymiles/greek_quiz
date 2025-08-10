import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('el'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @all_dictionaries_updated.
  ///
  /// In en, this message translates to:
  /// **'All dictionaries updated!'**
  String get all_dictionaries_updated;

  /// No description provided for @answer_language_picker.
  ///
  /// In en, this message translates to:
  /// **'Answer language'**
  String get answer_language_picker;

  /// No description provided for @appearance_section_header.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get appearance_section_header;

  /// No description provided for @answers_sounds_toggle.
  ///
  /// In en, this message translates to:
  /// **'Answer sounds'**
  String get answers_sounds_toggle;

  /// No description provided for @autoplay_sound_toggle.
  ///
  /// In en, this message translates to:
  /// **'Autoplay sound'**
  String get autoplay_sound_toggle;

  /// No description provided for @button_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get button_done;

  /// No description provided for @card_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get card_mode_title;

  /// No description provided for @check_button.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check_button;

  /// No description provided for @correct_answer_feedback.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct_answer_feedback;

  /// No description provided for @custom_url_label.
  ///
  /// In en, this message translates to:
  /// **'URL of your dictionary (.json)'**
  String get custom_url_label;

  /// No description provided for @dictionaries_section_header.
  ///
  /// In en, this message translates to:
  /// **'DICTIONARIES'**
  String get dictionaries_section_header;

  /// No description provided for @dictionary_source_picker.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get dictionary_source_picker;

  /// No description provided for @display_section_header.
  ///
  /// In en, this message translates to:
  /// **'DISPLAY'**
  String get display_section_header;

  /// No description provided for @download_and_save_dictionaries.
  ///
  /// In en, this message translates to:
  /// **'Download and save dictionaries'**
  String get download_and_save_dictionaries;

  /// No description provided for @download_error.
  ///
  /// In en, this message translates to:
  /// **'Download error'**
  String get download_error;

  /// No description provided for @download_success.
  ///
  /// In en, this message translates to:
  /// **'Download successful'**
  String get download_success;

  /// No description provided for @downloading_dictionaries.
  ///
  /// In en, this message translates to:
  /// **'Downloading dictionaries...'**
  String get downloading_dictionaries;

  /// No description provided for @enter_dictionaries_file_address.
  ///
  /// In en, this message translates to:
  /// **'Enter dictionaries file address'**
  String get enter_dictionaries_file_address;

  /// No description provided for @error_loading_dictionaries.
  ///
  /// In en, this message translates to:
  /// **'Error loading dictionaries: '**
  String get error_loading_dictionaries;

  /// No description provided for @error_no_dictionaries_selected.
  ///
  /// In en, this message translates to:
  /// **'No dictionaries selected'**
  String get error_no_dictionaries_selected;

  /// No description provided for @error_no_words_loaded.
  ///
  /// In en, this message translates to:
  /// **'No words loaded'**
  String get error_no_words_loaded;

  /// No description provided for @feedback_correct.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get feedback_correct;

  /// No description provided for @feedback_wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong!'**
  String get feedback_wrong;

  /// No description provided for @help_navigation_title.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help_navigation_title;

  /// No description provided for @incorrect_answer_feedback.
  ///
  /// In en, this message translates to:
  /// **'Wrong. Correct answer: '**
  String get incorrect_answer_feedback;

  /// No description provided for @interface_language_picker.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get interface_language_picker;

  /// No description provided for @keyboard_mode_title.
  ///
  /// In en, this message translates to:
  /// **'I\'ll write'**
  String get keyboard_mode_title;

  /// No description provided for @language_el.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get language_el;

  /// No description provided for @language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_en;

  /// No description provided for @language_ru.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get language_ru;

  /// No description provided for @language_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get language_system;

  /// No description provided for @languages_section_header.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGES'**
  String get languages_section_header;

  /// No description provided for @next_button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next_button;

  /// No description provided for @no_dictionaries_available.
  ///
  /// In en, this message translates to:
  /// **'No dictionaries available. Please download.'**
  String get no_dictionaries_available;

  /// No description provided for @no_words_loaded.
  ///
  /// In en, this message translates to:
  /// **'No words loaded.'**
  String get no_words_loaded;

  /// No description provided for @picker_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Select an option'**
  String get picker_dialog_title;

  /// No description provided for @quiz_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz_mode_title;

  /// No description provided for @rules_navigation_title.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules_navigation_title;

  /// No description provided for @score_label.
  ///
  /// In en, this message translates to:
  /// **'Score: '**
  String get score_label;

  /// No description provided for @search_bar_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_bar_placeholder;

  /// No description provided for @select_dictionaries_title.
  ///
  /// In en, this message translates to:
  /// **'Select Dictionaries'**
  String get select_dictionaries_title;

  /// No description provided for @show_answer_button.
  ///
  /// In en, this message translates to:
  /// **'Show Answer'**
  String get show_answer_button;

  /// No description provided for @show_article_toggle.
  ///
  /// In en, this message translates to:
  /// **'Show article'**
  String get show_article_toggle;

  /// No description provided for @show_transcription_toggle.
  ///
  /// In en, this message translates to:
  /// **'Show transcription'**
  String get show_transcription_toggle;

  /// No description provided for @sound_section_header.
  ///
  /// In en, this message translates to:
  /// **'SOUND'**
  String get sound_section_header;

  /// No description provided for @source_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom URL'**
  String get source_custom;

  /// No description provided for @source_local.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get source_local;

  /// No description provided for @studied_language_picker.
  ///
  /// In en, this message translates to:
  /// **'Study language'**
  String get studied_language_picker;

  /// No description provided for @talk_show_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Talk Show'**
  String get talk_show_mode_title;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_picker.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme_picker;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_system;

  /// No description provided for @title_settings_navigation.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get title_settings_navigation;

  /// No description provided for @use_all_words_in_answers.
  ///
  /// In en, this message translates to:
  /// **'All the words in the answers'**
  String get use_all_words_in_answers;

  /// No description provided for @use_all_words_subtitle.
  ///
  /// In en, this message translates to:
  /// **'For \'Quiz\' and \'Cards\' modes'**
  String get use_all_words_subtitle;

  /// No description provided for @use_all_words_toggle.
  ///
  /// In en, this message translates to:
  /// **'Use all words'**
  String get use_all_words_toggle;

  /// No description provided for @words_list_title.
  ///
  /// In en, this message translates to:
  /// **'Words list'**
  String get words_list_title;

  /// No description provided for @your_translation_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Your translation'**
  String get your_translation_placeholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['el', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
