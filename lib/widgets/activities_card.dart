import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/character.dart';
import 'activity_list_item.dart';

/// Displays the list of available activities.
class ActivitiesCard extends StatelessWidget {
  const ActivitiesCard({
    super.key,
    required this.activities,
    required this.character,
    required this.currentActivityId,
    required this.hasActiveActivity,
    required this.onStartActivity,
  });

  final List<Activity> activities;
  final Character character;
  final String? currentActivityId;
  final bool hasActiveActivity;
  final void Function(Activity activity) onStartActivity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Activities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return ActivityListItem(
                  activity: activity,
                  character: character,
                  isCurrentActivity: currentActivityId == activity.id,
                  canStart: !hasActiveActivity,
                  onStart: () => onStartActivity(activity),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
