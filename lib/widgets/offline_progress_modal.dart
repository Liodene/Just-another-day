import 'package:flutter/material.dart';

import '../models/character.dart';
import '../models/offline_progress.dart';

/// A modal dialog that displays when the user returns after being offline.
///
/// Shows the time elapsed (both real-world and in-game equivalent) and
/// the current game state. This is informational only - no passive gains
/// are applied during offline time.
class OfflineProgressModal extends StatelessWidget {
  const OfflineProgressModal({
    super.key,
    required this.progressData,
    required this.onContinue,
  });

  /// The offline progress data to display.
  final OfflineProgressData progressData;

  /// Callback when the user wants to continue playing.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.schedule, size: 28),
          SizedBox(width: 8),
          Text('Welcome Back!'),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve been away for a while.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            _buildTimeInfo(
              context,
              'Real-world time',
              progressData.formattedRealTime,
            ),
            const SizedBox(height: 8),
            _buildTimeInfo(
              context,
              'Game-time equivalent',
              progressData.formattedGameTime,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Current Status:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Day ${progressData.dayCount}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12),
            // Display all stats
            _StatDisplayRow(
              statType: StatType.strength,
              value: progressData.currentStats.strength,
            ),
            _StatDisplayRow(
              statType: StatType.intelligence,
              value: progressData.currentStats.intelligence,
            ),
            _StatDisplayRow(
              statType: StatType.endurance,
              value: progressData.currentStats.endurance,
            ),
            _StatDisplayRow(
              statType: StatType.charisma,
              value: progressData.currentStats.charisma,
            ),
            _StatDisplayRow(
              statType: StatType.agility,
              value: progressData.currentStats.agility,
            ),
            const SizedBox(height: 16),
            Text(
              'No activities were processed while you were away.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () {
            onContinue();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

/// A row displaying a stat with its icon and current value.
class _StatDisplayRow extends StatelessWidget {
  const _StatDisplayRow({required this.statType, required this.value});

  final StatType statType;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getStatIcon(statType),
            size: 20,
            color: _getStatColor(statType),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatName(statType),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _getStatName(StatType type) {
    switch (type) {
      case StatType.strength:
        return 'Strength';
      case StatType.intelligence:
        return 'Intelligence';
      case StatType.endurance:
        return 'Endurance';
      case StatType.charisma:
        return 'Charisma';
      case StatType.agility:
        return 'Agility';
    }
  }

  IconData _getStatIcon(StatType type) {
    switch (type) {
      case StatType.strength:
        return Icons.fitness_center;
      case StatType.intelligence:
        return Icons.psychology;
      case StatType.endurance:
        return Icons.favorite;
      case StatType.charisma:
        return Icons.record_voice_over;
      case StatType.agility:
        return Icons.directions_run;
    }
  }

  Color _getStatColor(StatType type) {
    switch (type) {
      case StatType.strength:
        return Colors.red;
      case StatType.intelligence:
        return Colors.blue;
      case StatType.endurance:
        return Colors.green;
      case StatType.charisma:
        return Colors.orange;
      case StatType.agility:
        return Colors.purple;
    }
  }
}
