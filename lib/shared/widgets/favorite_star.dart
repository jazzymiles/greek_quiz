// lib/shared/widgets/favorite_star.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greek_quiz/data/models/word.dart';
// ✅ правильный импорт сервиса избранного
import 'package:greek_quiz/features/favorites/favorites_service.dart';
// провайдер-экшен для добавления
import 'package:greek_quiz/features/favorites/add_to_favorites_provider.dart';

/// Кнопка-звёздочка для добавления слова в избранное.
/// - Заполненная звезда, если слово уже в избранном.
/// - Контурная — если нет; по тапу добавляет.
class FavoriteStar extends ConsumerWidget {
  const FavoriteStar({super.key, required this.word});

  final Word word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Читаем актуальный флаг избранного (селектором, чтобы не перерисовывать лишнее)
    final isFavorite = ref.watch(
      favoritesServiceProvider.select((svc) => svc.isFavorite(word.id)),
    );

    final colorScheme = Theme.of(context).colorScheme;
    final addToFav = ref.read(addToFavoritesProvider);

    return IconButton(
      tooltip: isFavorite ? 'Favorites' : 'Add to favorites',
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite
            ? colorScheme.tertiary
            : colorScheme.onSurface.withOpacity(0.7),
      ),
      onPressed: isFavorite
          ? null // уже добавлено — блокируем кнопку
          : () async {
        await addToFav(word);
      },
    );
  }
}
