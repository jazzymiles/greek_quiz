import 'package:flutter/foundation.dart';

@immutable
class Word {
  final String id;
  final String ru;
  final String el;
  final String? en;
  final String transcription;
  final String? partOfSpeech;
  final String dictionaryId;
  final String? gender;

  final String? ruExample;
  final String? elExample;
  final String? enExample;

  const Word({
    required this.id,
    required this.ru,
    required this.el,
    this.en,
    required this.transcription,
    this.partOfSpeech,
    required this.dictionaryId,
    this.gender,
    this.ruExample,
    this.elExample,
    this.enExample,
  });

  factory Word.fromJson(Map<String, dynamic> json, String dictionaryId) {
    return Word(
      id: (json['el'] as String?) ?? '',
      ru: (json['ru'] as String?) ?? '',
      el: (json['el'] as String?) ?? '',
      en: json['en'] as String?,
      transcription: (json['transcription'] as String?) ?? '',
      partOfSpeech: json['part_of_speech'] as String?,
      dictionaryId: dictionaryId,
      gender: json['gender'] as String?,
      ruExample: json['ru_example'] as String?,
      elExample: json['el_example'] as String?,
      enExample: json['en_example'] as String?,
    );
  }

  String? getUsageExampleForLanguage(String langCode) {
    return switch (langCode) {
      'ru' => ruExample,
      'el' => elExample,
      'en' => enExample,
      _ => elExample,
    };
  }
}

@immutable
class QuizAnswer {
  final Word word;
  final String userAnswer;
  final bool isCorrect;

  const QuizAnswer({
    required this.word,
    required this.userAnswer,
    required this.isCorrect,
  });
}