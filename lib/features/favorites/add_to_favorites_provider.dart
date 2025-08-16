// lib/features/favorites/add_to_favorites_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/favorites/favorites_service.dart';
import 'package:greek_quiz/data/services/dictionary_service.dart';

/// Базовые типы действий
typedef AddToFavorites = Future<void> Function(Word word);
typedef RemoveFromFavorites = Future<void> Function(String wordId);
typedef ToggleFavorite = Future<void> Function(Word word);
typedef IsFavoriteSync = bool Function(String wordId);

/// Добавить слово в избранное с синхронизацией
final addToFavoritesProvider = Provider<AddToFavorites>((ref) {
  final favs = ref.read(favoritesServiceProvider);
  final dict = ref.read(dictionaryServiceProvider);
  return (Word word) async {
    await favs.add(word);
    // Обновляем кэш в DictionaryService
    await dict.refreshFavorites();
  };
});

/// Удалить слово из избранного с синхронизацией
final removeFromFavoritesProvider = Provider<RemoveFromFavorites>((ref) {
  final favs = ref.read(favoritesServiceProvider);
  final dict = ref.read(dictionaryServiceProvider);
  return (String wordId) async {
    await favs.removeById(wordId);
    // Обновляем кэш в DictionaryService
    await dict.refreshFavorites();
  };
});

/// Переключить избранное у слова с синхронизацией
final toggleFavoriteProvider = Provider<ToggleFavorite>((ref) {
  final favs = ref.read(favoritesServiceProvider);
  final dict = ref.read(dictionaryServiceProvider);
  return (Word word) async {
    await favs.toggle(word);
    // Обновляем кэш в DictionaryService
    await dict.refreshFavorites();
  };
});

/// Синхронная проверка (может быть ложной до первой загрузки; UI обновится после notifyListeners)
final isFavoriteSyncProvider = Provider<IsFavoriteSync>((ref) {
  final favs = ref.read(favoritesServiceProvider);
  return (String wordId) => favs.isFavorite(wordId);
});

/// Реактивный провайдер-фэмили: true/false для конкретного wordId.
/// Удобно для привязки в виджете (звёздочка и т.д.).
final isFavoriteProvider = Provider.family<bool, String>((ref, wordId) {
  // подписываемся только на boolean конкретного id
  return ref.watch(
    favoritesServiceProvider.select((svc) => svc.isFavorite(wordId)),
  );
});