import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/character.dart';

/// Displays a single activity item with details and start button.
class ActivityListItem extends StatelessWidget {
  const ActivityListItem({
    super.key,
    required this.activity,
    required this.character,
    required this.isCurrentActivity,
    required this.canStart,
    required this.onStart,
    this.onAddToPlan,
  });

  final Activity activity;
  final Character character;
  final bool isCurrentActivity;
  final bool canStart;
  final VoidCallback onStart;

  /// Callback to add this activity to the plan. If null, no add button shown.
  final VoidCallback? onAddToPlan;

  @override
  Widget build(BuildContext context) {
    final meetsRequirements = activity.meetsRequirements(character.stats);
    final completions = character.getCompletions(activity.id);
    final coefficient = character.getDifficultyCoefficient(activity.id);
    final duration = activity.calculateDuration(
      character.stats,
      difficultyCoefficient: coefficient,
    );

    return Card(
      color: isCurrentActivity
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: ListTile(
        title: Text(activity.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.description),
            const SizedBox(height: 4),
            Text(
              'Duration: ${duration.toStringAsFixed(1)}s | x$completions',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Rewards: ${_formatRewards(activity.rewards)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onAddToPlan != null)
              IconButton(
                icon: const Icon(Icons.playlist_add),
                tooltip: 'Add to plan',
                onPressed: meetsRequirements ? onAddToPlan : null,
              ),
            ElevatedButton(
              onPressed: meetsRequirements && canStart ? onStart : null,
              child: Text(meetsRequirements ? 'Start' : 'Locked'),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatRewards(Map<StatType, double> rewards) {
    return rewards.entries.map((e) {
      final statName = e.key.name.substring(0, 3).toUpperCase();
      return '+${e.value.toStringAsFixed(2)} $statName';
    }).join(', ');
  }
}
