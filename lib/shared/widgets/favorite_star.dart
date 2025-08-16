// lib/shared/widgets/favorite_star.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greek_quiz/data/models/word.dart';
import 'package:greek_quiz/features/favorites/favorites_service.dart';
import 'package:greek_quiz/features/favorites/add_to_favorites_provider.dart';

/// Кнопка-звёздочка для добавления/удаления слова в избранное
class FavoriteStar extends ConsumerWidget {
  const FavoriteStar({super.key, required this.word});

  final Word word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Читаем актуальный флаг избранного
    final isFavorite = ref.watch(
      favoritesServiceProvider.select((svc) => svc.isFavorite(word.id)),
    );

    final colorScheme = Theme.of(context).colorScheme;
    final toggleFav = ref.read(toggleFavoriteProvider);

    return IconButton(
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      icon: Icon(
        isFavorite ? Icons.star : Icons.star_border,
        color: isFavorite
            ? colorScheme.tertiary
            : colorScheme.onSurface.withOpacity(0.7),
      ),
      onPressed: () async {
        await toggleFav(word);
      },
    );
  }
}