// lib/data/models/dictionary_info.dart
import 'package:flutter/foundation.dart';

@immutable
class DictionaryInfo {
  final String file;
  final String nameRu;
  final String nameEn;
  final String nameEl;
  final String filePath; // URL для скачивания

  const DictionaryInfo({
    required this.file,
    required this.nameRu,
    required this.nameEn,
    required this.nameEl,
    required this.filePath,
  });

  // ИСПРАВЛЕНИЕ: Используем правильный ключ 'filePath'
  factory DictionaryInfo.fromJson(Map<String, dynamic> json) {
    return DictionaryInfo(
      file: json['file'] as String,
      nameRu: json['name_ru'] as String,
      nameEn: json['name_en'] as String,
      nameEl: json['name_el'] as String,
      filePath: json['filePath'] as String, // Правильный ключ
    );
  }

  String getLocalizedName(String langCode) {
    return switch (langCode) {
      'ru' => nameRu, 'el' => nameEl, _ => nameEn,
    };
  }
}