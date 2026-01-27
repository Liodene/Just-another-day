import 'package:flutter/material.dart';

import '../models/game_time.dart';

/// Displays the in-game day count and time.
class GameTimeDisplay extends StatelessWidget {
  const GameTimeDisplay({super.key, required this.gameTime});

  final GameTime gameTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 16),
          const SizedBox(width: 4),
          Text(
            'Day ${gameTime.dayCount}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 12),
          const Icon(Icons.access_time, size: 16),
          const SizedBox(width: 4),
          Text(
            gameTime.formattedTime,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
