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
    this.dailyCompletions = 0,
    this.maxCompletions = 0,
  });

  final Activity activity;
  final Character character;
  final bool isCurrentActivity;
  final bool canStart;
  final VoidCallback onStart;

  /// Number of completions for this activity today.
  final int dailyCompletions;

  /// Record (max) completions for this activity.
  final int maxCompletions;

  @override
  Widget build(BuildContext context) {
    final meetsRequirements = activity.meetsRequirements(character.stats);
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
        title: Row(
          children: [
            Expanded(child: Text(activity.name)),
            _CompletionBadge(daily: dailyCompletions, max: maxCompletions),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity.description),
            const SizedBox(height: 4),
            Text(
              'Duration: ${duration.toStringAsFixed(1)}s',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Rewards: ${_formatRewards(activity.rewards)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: meetsRequirements && canStart ? onStart : null,
          child: Text(meetsRequirements ? 'Start' : 'Locked'),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatRewards(Map<StatType, double> rewards) {
    return rewards.entries
        .map((e) {
          final statName = e.key.name.substring(0, 3).toUpperCase();
          return '+${e.value.toStringAsFixed(2)} $statName';
        })
        .join(', ');
  }
}

/// Badge showing daily and max completions for an activity.
class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.daily, required this.max});

  final int daily;
  final int max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNewRecord = daily > max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNewRecord
            ? Colors.green.withValues(alpha: 0.2)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isNewRecord ? Border.all(color: Colors.green, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$daily',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isNewRecord ? Colors.green[700] : null,
            ),
          ),
          Text(
            ' / $max',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
