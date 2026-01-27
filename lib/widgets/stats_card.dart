import 'package:flutter/material.dart';

import '../models/character.dart';
import 'stat_row.dart';

/// Displays character name, total completions, and all stats.
class StatsCard extends StatelessWidget {
  const StatsCard({super.key, required this.character});

  final Character character;

  @override
  Widget build(BuildContext context) {
    final stats = character.stats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  character.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Total: ${character.totalCompletions} completions',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            StatRow(name: 'Strength', value: stats.strength, color: Colors.red),
            StatRow(
              name: 'Intelligence',
              value: stats.intelligence,
              color: Colors.blue,
            ),
            StatRow(
              name: 'Endurance',
              value: stats.endurance,
              color: Colors.green,
            ),
            StatRow(
              name: 'Charisma',
              value: stats.charisma,
              color: Colors.orange,
            ),
            StatRow(
              name: 'Agility',
              value: stats.agility,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}
