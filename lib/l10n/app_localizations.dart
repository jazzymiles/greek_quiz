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
  /// **'Ελληνικά'**
  String get language_el;

  /// No description provided for @language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_en;

  /// No description provided for @language_ru.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
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

  /// No description provided for @allDictionariesUpdated.
  ///
  /// In en, this message translates to:
  /// **'All dictionaries updated!'**
  String get allDictionariesUpdated;

  /// No description provided for @answerInLanguage.
  ///
  /// In en, this message translates to:
  /// **'Answer in language'**
  String get answerInLanguage;

  /// No description provided for @answersSoundsToggle.
  ///
  /// In en, this message translates to:
  /// **'Answers sound'**
  String get answersSoundsToggle;

  /// No description provided for @appearanceSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance Settings'**
  String get appearanceSettingsSection;

  /// No description provided for @autoplaySoundToggle.
  ///
  /// In en, this message translates to:
  /// **'Word sound'**
  String get autoplaySoundToggle;

  /// No description provided for @buttonCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get buttonCheck;

  /// No description provided for @buttonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get buttonClose;

  /// No description provided for @buttonDictionaries.
  ///
  /// In en, this message translates to:
  /// **'Dictionaries'**
  String get buttonDictionaries;

  /// No description provided for @buttonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get buttonNext;

  /// No description provided for @buttonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get buttonRefresh;

  /// No description provided for @buttonRules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get buttonRules;

  /// No description provided for @buttonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get buttonSettings;

  /// No description provided for @button_show_words.
  ///
  /// In en, this message translates to:
  /// **'Show words'**
  String get button_show_words;

  /// No description provided for @buttonShowWords.
  ///
  /// In en, this message translates to:
  /// **'Show words'**
  String get buttonShowWords;

  /// No description provided for @clearingOldDictionaries.
  ///
  /// In en, this message translates to:
  /// **'Clearing old dictionaries'**
  String get clearingOldDictionaries;

  /// No description provided for @customUrlDictionaries.
  ///
  /// In en, this message translates to:
  /// **'Custom URL (from internet)'**
  String get customUrlDictionaries;

  /// No description provided for @dictionariesSection.
  ///
  /// In en, this message translates to:
  /// **'Dictionaries'**
  String get dictionariesSection;

  /// No description provided for @dictionaryDownloadOption1.
  ///
  /// In en, this message translates to:
  /// **'Standart'**
  String get dictionaryDownloadOption1;

  /// No description provided for @dictionaryDownloadOption2.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get dictionaryDownloadOption2;

  /// No description provided for @dictionarySource.
  ///
  /// In en, this message translates to:
  /// **'Dictionary Source'**
  String get dictionarySource;

  /// No description provided for @downloadStatus1.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloadStatus1;

  /// No description provided for @downloadStatusText.
  ///
  /// In en, this message translates to:
  /// **'Loading dictionary:'**
  String get downloadStatusText;

  /// No description provided for @downloadingDictionariesList.
  ///
  /// In en, this message translates to:
  /// **'Downloading dictionaries list...'**
  String get downloadingDictionariesList;

  /// No description provided for @downloadingDictionary.
  ///
  /// In en, this message translates to:
  /// **'Downloading dictionary: {dictionaryName} ({progress} of {total})...'**
  String downloadingDictionary(
    Object dictionaryName,
    Object progress,
    Object total,
  );

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @errorDownloadingDictionaries.
  ///
  /// In en, this message translates to:
  /// **'Error downloading dictionaries: {error}'**
  String errorDownloadingDictionaries(Object error);

  /// No description provided for @errorIncorrectDownloadUrl.
  ///
  /// In en, this message translates to:
  /// **'Error: Invalid download URL.'**
  String get errorIncorrectDownloadUrl;

  /// No description provided for @errorInvalidDictionariesListUrl.
  ///
  /// In en, this message translates to:
  /// **'Error: Invalid dictionaries list'**
  String get errorInvalidDictionariesListUrl;

  /// No description provided for @errorUnknownDictionarySource.
  ///
  /// In en, this message translates to:
  /// **'Error: Unknown dictionary source.'**
  String get errorUnknownDictionarySource;

  /// No description provided for @greekLanguage.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get greekLanguage;

  /// No description provided for @greekLanguageOption.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get greekLanguageOption;

  /// No description provided for @helpUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Help updated!'**
  String get helpUpdatedMessage;

  /// No description provided for @helpViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpViewTitle;

  /// No description provided for @interfaceLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Interface Language'**
  String get interfaceLanguageSection;

  /// No description provided for @languageGreek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get languageGreek;

  /// No description provided for @languageInterfacePicker.
  ///
  /// In en, this message translates to:
  /// **'Interface Language'**
  String get languageInterfacePicker;

  /// No description provided for @languageOptionEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageOptionEnglish;

  /// No description provided for @languageOptionGreek.
  ///
  /// In en, this message translates to:
  /// **'Greek'**
  String get languageOptionGreek;

  /// No description provided for @languageOptionRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get languageOptionRussian;

  /// No description provided for @languageOptionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageOptionSystem;

  /// No description provided for @languageSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languageSettingsSection;

  /// No description provided for @learningSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Learning Settings'**
  String get learningSettingsSection;

  /// No description provided for @loadingDictionariesMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading dictionary'**
  String get loadingDictionariesMessage;

  /// No description provided for @modeCardsDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get modeCardsDisplayName;

  /// No description provided for @modeKeyboardDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Type In'**
  String get modeKeyboardDisplayName;

  /// No description provided for @modeQuizDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get modeQuizDisplayName;

  /// No description provided for @modeTalkshowDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Talk show'**
  String get modeTalkshowDisplayName;

  /// No description provided for @noAnswerSelectedFeedback.
  ///
  /// In en, this message translates to:
  /// **'Error: No answer selected.\nShowing correct answer.'**
  String get noAnswerSelectedFeedback;

  /// No description provided for @palceHolderSearch.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get palceHolderSearch;

  /// No description provided for @quizLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Quiz Language'**
  String get quizLanguageSection;

  /// No description provided for @quizSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Quiz settings'**
  String get quizSettingsSection;

  /// No description provided for @rulesUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Rules updated!'**
  String get rulesUpdatedMessage;

  /// No description provided for @rulesViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rulesViewTitle;

  /// No description provided for @russianLanguage.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russianLanguage;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchPlaceholder;

  /// No description provided for @selectAtLeastOneDictionary.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one dictionary.\nTo do this, click the button at the top with this icon'**
  String get selectAtLeastOneDictionary;

  /// No description provided for @standardDictionaries.
  ///
  /// In en, this message translates to:
  /// **'Standard dictionaries'**
  String get standardDictionaries;

  /// No description provided for @studiedLanguagePicker.
  ///
  /// In en, this message translates to:
  /// **'Studied language'**
  String get studiedLanguagePicker;

  /// No description provided for @themeApp.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get themeApp;

  /// No description provided for @themeAppTitle.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get themeAppTitle;

  /// No description provided for @titleQuizMode.
  ///
  /// In en, this message translates to:
  /// **'Quiz mode'**
  String get titleQuizMode;

  /// No description provided for @titleSelectDictionaries.
  ///
  /// In en, this message translates to:
  /// **'Select dictionaries'**
  String get titleSelectDictionaries;

  /// No description provided for @titleWordsList.
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get titleWordsList;

  /// No description provided for @updateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Update error: {error}.'**
  String updateErrorMessage(Object error);

  /// No description provided for @wordsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Words list'**
  String get wordsListTitle;

  /// No description provided for @answerLanguagePicker.
  ///
  /// In en, this message translates to:
  /// **'Answer language'**
  String get answerLanguagePicker;

  /// No description provided for @useAllWordsToggle.
  ///
  /// In en, this message translates to:
  /// **'All the words in the answers'**
  String get useAllWordsToggle;

  /// No description provided for @buttonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get buttonDone;

  /// No description provided for @downloadAndSaveDictionaries.
  ///
  /// In en, this message translates to:
  /// **'Download and save dictionaries'**
  String get downloadAndSaveDictionaries;

  /// No description provided for @enterDictionariesFileAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter dictionaries.txt file address'**
  String get enterDictionariesFileAddress;

  /// No description provided for @showArticleToggle.
  ///
  /// In en, this message translates to:
  /// **'Show articles'**
  String get showArticleToggle;

  /// No description provided for @showTranscriptionToggle.
  ///
  /// In en, this message translates to:
  /// **'Show transcription'**
  String get showTranscriptionToggle;

  /// No description provided for @yourTranslationPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your translation'**
  String get yourTranslationPlaceholder;
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
