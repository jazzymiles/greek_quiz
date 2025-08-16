// lib/features/favorites/favorites_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:greek_quiz/data/models/word.dart';

/// Простой сервис «Избранное»:
/// - хранит set id слов;
/// - сохраняет/читает в файл JSON;
/// - уведомляет слушателей через ChangeNotifier.
class FavoritesService extends ChangeNotifier {
  FavoritesService();

  final Set<String> _ids = <String>{};

  bool _loaded = false;
  Future<void>? _loadFuture;

  /// Инициализация (ленивая): читаем файл 1 раз.
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loadFuture ??= _loadFromDisk();
    try {
      await _loadFuture;
    } finally {
      _loadFuture = null;
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final favDir = Directory('${dir.path}/favorites');
    if (!await favDir.exists()) {
      await favDir.create(recursive: true);
    }
    return File('${favDir.path}/user_favs.json');
    // формат файла: ["dictId|el", "anotherId|..."]
  }

  Future<void> _loadFromDisk() async {
    try {
      final f = await _file();
      if (await f.exists()) {
        final raw = await f.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _ids
            ..clear()
            ..addAll(decoded.whereType<String>());
        }
      } else {
        // создаём пустой файл
        await f.writeAsString(jsonEncode(<String>[]));
      }
    } catch (_) {
      // игнор: пусть будет пустой набор
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final f = await _file();
      await f.writeAsString(jsonEncode(_ids.toList()));
    } catch (_) {
      // игнор ошибок записи
    }
  }

  // --- Публичное API ---

  /// Добавить слово в избранное.
  Future<void> add(Word word) async {
    await _ensureLoaded();
    if (_ids.add(word.id)) {
      await _saveToDisk();
      notifyListeners();
    }
  }

  /// Удалить по id.
  Future<void> removeById(String wordId) async {
    await _ensureLoaded();
    if (_ids.remove(wordId)) {
      await _saveToDisk();
      notifyListeners();
    }
  }

  /// Переключить состояние избранного.
  Future<void> toggle(Word word) async {
    await _ensureLoaded();
    if (_ids.contains(word.id)) {
      _ids.remove(word.id);
    } else {
      _ids.add(word.id);
    }
    await _saveToDisk();
    notifyListeners();
  }

  /// Проверить, в избранном ли id.
  bool isFavorite(String wordId) {
    // быстрый путь: если ещё не грузились — вернём false, UI позже обновится
    return _ids.contains(wordId);
  }

  /// Текущее количество.
  int get count => _ids.length;

  /// Все id (read-only snapshot).
  List<String> get allIds => List.unmodifiable(_ids);
}

// Провайдер сервиса избранного.
final favoritesServiceProvider =
ChangeNotifierProvider<FavoritesService>((ref) => FavoritesService());
