import 'package:flutter/material.dart';

import '../models/activity.dart';

/// Displays and manages the activity plan (queue of activities).
class ActivityPlanCard extends StatelessWidget {
  const ActivityPlanCard({
    super.key,
    required this.activityPlan,
    required this.currentActivityId,
    required this.onRemoveFromPlan,
    required this.onReorderPlan,
    required this.onClearPlan,
  });

  /// The list of planned activities.
  final List<Activity> activityPlan;

  /// The ID of the currently running activity (if any).
  final String? currentActivityId;

  /// Callback to remove an activity from the plan by index.
  final void Function(int index) onRemoveFromPlan;

  /// Callback to reorder activities in the plan.
  final void Function(int oldIndex, int newIndex) onReorderPlan;

  /// Callback to clear the entire plan.
  final VoidCallback onClearPlan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            if (activityPlan.isEmpty)
              _buildEmptyMessage()
            else
              _buildPlanList(context),
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
          'Activity Plan',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (activityPlan.isNotEmpty)
          TextButton.icon(
            onPressed: onClearPlan,
            icon: const Icon(Icons.clear_all, size: 18),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyMessage() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'No activities planned. Add activities from the list below.',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildPlanList(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activityPlan.length,
      onReorder: onReorderPlan,
      itemBuilder: (context, index) {
        final activity = activityPlan[index];
        final isCurrentActivity =
            index == 0 && currentActivityId == activity.id;

        return _ActivityPlanItem(
          key: ValueKey('plan_${activity.id}_$index'),
          activity: activity,
          index: index,
          isCurrentActivity: isCurrentActivity,
          onRemove: () => onRemoveFromPlan(index),
        );
      },
    );
  }
}

class _ActivityPlanItem extends StatelessWidget {
  const _ActivityPlanItem({
    super.key,
    required this.activity,
    required this.index,
    required this.isCurrentActivity,
    required this.onRemove,
  });

  final Activity activity;
  final int index;
  final bool isCurrentActivity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: isCurrentActivity
          ? theme.colorScheme.primaryContainer
          : theme.cardColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentActivity
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: isCurrentActivity
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          child: Text('${index + 1}'),
        ),
        title: Text(
          activity.name,
          style: TextStyle(
            fontWeight: isCurrentActivity ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: isCurrentActivity
            ? const Text(
                'In progress',
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.red,
              tooltip: isCurrentActivity
                  ? 'Cancel and remove'
                  : 'Remove from plan',
              onPressed: onRemove,
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ],
        ),
      ),
    );
  }
}
