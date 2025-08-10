import 'package:flutter/foundation.dart';

@immutable
class Word {
  final String id;
  final String ru;
  final String el;
  final String? en;
  final String transcription;
  final String? partOfSpeech;
  final String? usage_example;
  final String dictionaryId;
  final String? gender;

  const Word({
    required this.id,
    required this.ru,
    required this.el,
    this.en,
    required this.transcription,
    this.partOfSpeech,
    this.usage_example,
    required this.dictionaryId,
    this.gender,
  });

  factory Word.fromJson(Map<String, dynamic> json, String dictionaryId) {
    return Word(
      id: (json['el'] as String?) ?? '',
      ru: (json['ru'] as String?) ?? '',
      el: (json['el'] as String?) ?? '',
      en: json['en'] as String?,
      transcription: (json['transcription'] as String?) ?? '',
      partOfSpeech: json['part_of_speech'] as String?,
      usage_example: json['usage_example'] as String?,
      dictionaryId: dictionaryId,
      gender: json['gender'] as String?,
    );
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