// lib/data/models/word.dart
import 'package:flutter/foundation.dart';
import 'dart:core';

@immutable
class Word {
  final String id;
  final String ru;
  final String el;
  final String? en;
  final String transcription;
  final String? partOfSpeech;
  final String? usage_example;
  final String dictionaryId; // ID словаря, из которого пришло слово

  const Word({
    required this.id,
    required this.ru,
    required this.el,
    this.en,
    required this.transcription,
    this.partOfSpeech,
    this.usage_example,
    required this.dictionaryId, // Добавлено в конструктор
  });

  // Конструктор теперь принимает ID словаря
  factory Word.fromJson(Map<String, dynamic> json, String dictionaryId) {
    return Word(
      id: (json['el'] as String?) ?? '',
      ru: (json['ru'] as String?) ?? '',
      el: (json['el'] as String?) ?? '',
      en: json['en'] as String?,
      transcription: (json['transcription'] as String?) ?? '',
      partOfSpeech: json['part_of_speech'] as String?,
      usage_example: json['usage_example'] as String?,
      dictionaryId: dictionaryId, // Присваиваем ID
    );
  }
}

// QuizAnswer без изменений
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