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

    // ---- ПРИМЕРЫ: поддержка двух вариантов источника ----
    Map<String, String>? examples;

    // 1) Старый формат: example: { el: "...", ru: "...", en: "..." }
    if (json['example'] is Map) {
      final raw = (json['example'] as Map);
      final map = <String, String>{};
      void putIfNonEmpty(String key, dynamic value) {
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) map[key] = s;
      }

      putIfNonEmpty('el', raw['el']);
      putIfNonEmpty('ru', raw['ru']);
      putIfNonEmpty('en', raw['en']);

      if (map.isNotEmpty) {
        examples = map;
      }
    }

    // 2) Новый формат: el_example / ru_example / en_example
    //    Берём их ТОЛЬКО если examples ещё не установлен из 1)
    if (examples == null) {
      final map = <String, String>{};

      final elEx = (json['el_example']?.toString().trim() ?? '');
      final ruEx = (json['ru_example']?.toString().trim() ?? '');
      final enEx = (json['en_example']?.toString().trim() ?? '');

      if (elEx.isNotEmpty) map['el'] = elEx;
      if (ruEx.isNotEmpty) map['ru'] = ruEx;
      if (enEx.isNotEmpty) map['en'] = enEx;

      if (map.isNotEmpty) {
        examples = map;
      }
    }
    // ------------------------------------------------------

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
    final v = examples?[langCode];
    if (v == null) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
}
