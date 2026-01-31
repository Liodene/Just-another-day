import 'package:flutter/material.dart';

import '../models/character.dart';

/// A modal dialog that displays when the day ends (time reaches 24:00).
///
/// Shows the accumulated stat gains for the day and provides a button
/// to start a new day, which applies the stat gains to the character.
class DayEndModal extends StatelessWidget {
  const DayEndModal({
    super.key,
    required this.dayCount,
    required this.dailyGains,
    required this.onStartNewDay,
  });

  /// The current day number that just ended.
  final int dayCount;

  /// The accumulated stat gains for the day.
  final Map<StatType, double> dailyGains;

  /// Callback when the user wants to start a new day.
  final VoidCallback onStartNewDay;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.nights_stay, size: 28),
          const SizedBox(width: 8),
          Text('Day $dayCount Complete'),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time is up! Here are your gains for today:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (dailyGains.isEmpty)
              Text(
                'No stat gains today.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              )
            else
              ...dailyGains.entries.map(
                (entry) =>
                    _StatGainRow(statType: entry.key, value: entry.value),
              ),
            const SizedBox(height: 16),
            Text(
              'Press the button below to apply your gains and start a new day.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton.icon(
          onPressed: () {
            onStartNewDay();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.wb_sunny),
          label: const Text('Start New Day'),
        ),
      ],
    );
  }
}

/// A row displaying a stat gain with its icon and value.
class _StatGainRow extends StatelessWidget {
  const _StatGainRow({required this.statType, required this.value});

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
            '+${value.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
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
