import 'package:flutter/material.dart';

import '../models/activity.dart';

/// Displays the current activity progress with controls.
class ActivityProgressCard extends StatelessWidget {
  const ActivityProgressCard({
    super.key,
    required this.progress,
    required this.autoRepeat,
    required this.onAutoRepeatChanged,
    required this.onStopActivity,
  });

  final ActivityProgress? progress;
  final bool autoRepeat;
  final ValueChanged<bool> onAutoRepeatChanged;
  final VoidCallback onStopActivity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            if (progress == null)
              _buildNoActivityMessage()
            else
              _buildProgressContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Current Activity',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          children: [
            const Text('Auto-repeat'),
            Switch(
              value: autoRepeat,
              onChanged: onAutoRepeatChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoActivityMessage() {
    return const Text(
      'No activity in progress. Select an activity below.',
      style: TextStyle(fontStyle: FontStyle.italic),
    );
  }

  Widget _buildProgressContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progress!.activity.name,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress!.progress,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(progress!.progress * 100).toStringAsFixed(1)}%'),
            Text(
              '${progress!.remainingTime.toStringAsFixed(1)}s remaining',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onStopActivity,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Stop Activity'),
        ),
      ],
    );
  }
}
