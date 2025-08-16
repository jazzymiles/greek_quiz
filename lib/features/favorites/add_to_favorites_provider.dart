// lib/features/favorites/add_to_favorites_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/favorites/favorites_service.dart';

/// Базовые типы действий
typedef AddToFavorites = Future<void> Function(Word word);
typedef RemoveFromFavorites = Future<void> Function(String wordId);
typedef ToggleFavorite = Future<void> Function(Word word);
typedef IsFavoriteSync = bool Function(String wordId);

/// Добавить слово в избранное
final addToFavoritesProvider = Provider<AddToFavorites>((ref) {
  final favs = ref.read(favoritesServiceProvider);
  return (Word word) => favs.add(word);
});

/// Удалить слово из избранного по id
final removeFromFavoritesProvider = Provider<RemoveFromFavorites>((ref) {
  final favs = ref.read(favoritesServiceProvider);
  return (String wordId) => favs.removeById(wordId);
});

/// Переключить избранное у слова
final toggleFavoriteProvider = Provider<ToggleFavorite>((ref) {
  final favs = ref.read(favoritesServiceProvider);
  return (Word word) => favs.toggle(word);
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
