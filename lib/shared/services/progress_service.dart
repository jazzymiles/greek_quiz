import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WordProgress {
  int correct;
  int wrong;
  bool starred;
  int lastSeenEpoch;

  WordProgress({
    this.correct = 0,
    this.wrong = 0,
    this.starred = false,
    int? lastSeenEpoch,
  }) : lastSeenEpoch = lastSeenEpoch ?? DateTime.now().millisecondsSinceEpoch;

  double get accuracy {
    final total = correct + wrong;
    return total == 0 ? 0.0 : correct / total;
  }

  Map<String, dynamic> toJson() => {
    'c': correct,
    'w': wrong,
    's': starred,
    't': lastSeenEpoch,
  };

  factory WordProgress.fromJson(Map<String, dynamic> j) => WordProgress(
    correct: j['c'] ?? 0,
    wrong: j['w'] ?? 0,
    starred: j['s'] ?? false,
    lastSeenEpoch: j['t'] ?? DateTime.now().millisecondsSinceEpoch,
  );
}

class ProgressService extends ChangeNotifier {
  static const _prefsKey = 'word_progress_v1';
  final Map<String, WordProgress> _cache = {};

  ProgressService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cache
          ..clear()
          ..addAll(map.map((k, v) => MapEntry(k, WordProgress.fromJson(v))));
      } catch (_) {
        // игнорируем битые данные
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _cache.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  WordProgress get(String wordId) => _cache[wordId] ?? WordProgress();

  Future<void> toggleStar(String wordId) async {
    final p = _cache.putIfAbsent(wordId, () => WordProgress());
    p.starred = !p.starred;
    await _save();
    notifyListeners();
  }

  Future<void> registerResult(String wordId, {required bool correct}) async {
    final p = _cache.putIfAbsent(wordId, () => WordProgress());
    if (correct) {
      p.correct++;
    } else {
      p.wrong++;
    }
    p.lastSeenEpoch = DateTime.now().millisecondsSinceEpoch;
    await _save();
    notifyListeners();
  }

  /// ids "слабых" слов: точность ниже [threshold] (например, 0.6)
  List<String> weakWordIds({double threshold = 0.6}) {
    return _cache.entries
        .where((e) => e.value.correct + e.value.wrong >= 3) // чтоб не брать новеньких
        .where((e) => e.value.accuracy < threshold)
        .map((e) => e.key)
        .toList();
  }

  List<String> starredIds() =>
      _cache.entries.where((e) => e.value.starred).map((e) => e.key).toList();
}

final progressServiceProvider =
ChangeNotifierProvider<ProgressService>((ref) => ProgressService());
