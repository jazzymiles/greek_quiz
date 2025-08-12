class Word {
  final String id;
  final String dictionaryId;

  final String el;
  final String ru;
  final String? en;

  final String transcription;
  final String? gender;

  // Доп. пример(ы) использования по языкам (если есть в данных)
  final Map<String, String>? examples;

  Word({
    required this.id,
    required this.dictionaryId,
    required this.el,
    required this.ru,
    required this.en,
    required this.transcription,
    required this.gender,
    required this.examples,
  });

  factory Word.fromJson(Map<String, dynamic> json, String dictionaryId) {
    final el = (json['el'] ?? '').toString();
    final ru = (json['ru'] ?? '').toString();
    final en = json['en']?.toString();
    final transcription = (json['transcription'] ?? '').toString();
    final gender = json['gender']?.toString();

    // id: либо из данных, либо составной (чтобы избежать конфликтов)
    final id = (json['id']?.toString() ?? '${dictionaryId}|$el');

    // примеры: ожидаем словарь строк по языкам (если нет — null)
    Map<String, String>? examples;
    if (json['examples'] is Map) {
      final raw = json['examples'] as Map;
      examples = raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
    }

    return Word(
      id: id,
      dictionaryId: dictionaryId,
      el: el,
      ru: ru,
      en: en,
      transcription: transcription,
      gender: gender,
      examples: examples,
    );
  }

  String? getUsageExampleForLanguage(String langCode) {
    return examples?[langCode];
  }
}
