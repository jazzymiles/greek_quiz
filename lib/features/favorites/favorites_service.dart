// lib/features/favorites/favorites_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:greek_quiz/data/models/word.dart';

/// Сервис для работы с избранным
/// Синхронизирован с DictionaryService через общий файл
class FavoritesService extends ChangeNotifier {
  FavoritesService();

  final Set<String> _ids = <String>{};

  bool _loaded = false;
  Future<void>? _loadFuture;

  /// Инициализация - читаем файл один раз
  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loadFuture ??= _loadFromDisk();
    try {
      await _loadFuture;
    } finally {
      _loadFuture = null;
    }
  }

  /// Используем тот же путь, что и DictionaryService для синхронизации
  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    final dictDir = Directory('${dir.path}/dictionaries');
    if (!await dictDir.exists()) {
      await dictDir.create(recursive: true);
    }
    // Используем имя файла из DictionaryService.favoritesFile
    return File('${dictDir.path}/user_favs.json');
  }

  Future<void> _loadFromDisk() async {
    try {
      final f = await _file();
      if (await f.exists()) {
        final raw = await f.readAsString();
        final decoded = jsonDecode(raw);

        // Поддерживаем два формата:
        // 1. Простой массив ID: ["id1", "id2"]
        // 2. Формат с ключом ids: {"ids": ["id1", "id2"]}
        if (decoded is List) {
          _ids
            ..clear()
            ..addAll(decoded.whereType<String>());
        } else if (decoded is Map && decoded['ids'] is List) {
          _ids
            ..clear()
            ..addAll((decoded['ids'] as List).whereType<String>());
        }
      } else {
        // Создаём пустой файл в формате для DictionaryService
        await f.writeAsString(jsonEncode({'ids': <String>[]}));
      }
    } catch (_) {
      // При ошибке создаём пустой файл
      try {
        final f = await _file();
        await f.writeAsString(jsonEncode({'ids': <String>[]}));
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveToDisk() async {
    try {
      final f = await _file();
      // Сохраняем в формате, который понимает DictionaryService
      await f.writeAsString(jsonEncode({'ids': _ids.toList()}));
    } catch (_) {
      // игнорируем ошибки записи
    }
  }

  // --- Публичное API ---

  /// Инициализация сервиса - вызывается при старте приложения
  Future<void> initialize() async {
    await _ensureLoaded();
  }

  /// Добавить слово в избранное
  Future<void> add(Word word) async {
    await _ensureLoaded();
    if (_ids.add(word.id)) {
      await _saveToDisk();
      notifyListeners();
    }
  }

  /// Удалить по id
  Future<void> removeById(String wordId) async {
    await _ensureLoaded();
    if (_ids.remove(wordId)) {
      await _saveToDisk();
      notifyListeners();
    }
  }

  /// Переключить состояние избранного
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

  /// Проверить, в избранном ли id
  bool isFavorite(String wordId) {
    // Возвращаем false до загрузки, UI обновится после notifyListeners
    return _ids.contains(wordId);
  }

  /// Текущее количество
  int get count => _ids.length;

  /// Все id (read-only snapshot)
  List<String> get allIds => List.unmodifiable(_ids);
}

// Провайдер сервиса избранного
final favoritesServiceProvider =
ChangeNotifierProvider<FavoritesService>((ref) => FavoritesService());