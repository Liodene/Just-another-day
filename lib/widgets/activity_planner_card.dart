import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/activity_manager.dart';
import '../engine/activity_planner.dart';
import '../models/activity.dart';
import '../models/character.dart';
import '../models/game_time.dart';
import '../models/planned_activity.dart';
import '../utils/time_utils.dart';

/// Displays the activity planner with queued activities.
class ActivityPlannerCard extends StatelessWidget {
  const ActivityPlannerCard({
    super.key,
    required this.activityManager,
    required this.character,
    required this.onAddActivity,
    required this.onCancelPlan,
  });

  final ActivityManager activityManager;
  final Character character;
  final VoidCallback onAddActivity;
  final VoidCallback onCancelPlan;

  ActivityPlanner get planner => activityManager.planner;
  GameTime get gameTime => activityManager.gameTime;

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
            _buildEstimatedTime(context),
            const SizedBox(height: 8),
            if (planner.queue.isEmpty)
              _buildEmptyMessage()
            else
              _buildQueueList(context),
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Text(
      'Activity Planner',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _buildEstimatedTime(BuildContext context) {
    final estimatedTime = activityManager.estimatePlanTime();
    final timeText = estimatedTime.inMicroseconds >= 0
        ? formatDurationCompact(estimatedTime)
        : 'Unlimited';

    // Calculate remaining time in the day
    final remainingTime = GameTime.maxDayDuration - gameTime.inGameTime;
    final exceedsDay = estimatedTime.inMicroseconds >= 0 && estimatedTime > remainingTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Estimated time: $timeText',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (exceedsDay) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber, size: 16, color: Colors.orange[800]),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Plan exceeds remaining day time '
                    '(${formatDurationCompact(remainingTime)} left)',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.orange[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyMessage() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'No activities planned. Add activities to create a plan.',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildQueueList(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: planner.queue.length,
      onReorder: planner.reorder,
      itemBuilder: (context, index) {
        final planned = planner.queue[index];
        final isFirst = index == 0;
        return _PlannedActivityItem(
          key: ValueKey('${planned.activity.id}_$index'),
          planned: planned,
          isActive: isFirst && activityManager.hasActiveActivity,
          onRemove: () => activityManager.removePlannedActivity(index),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    final canAdd = planner.canAddActivity();
    final hasPlan = planner.hasPlannedActivities;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: canAdd ? onAddActivity : null,
          icon: const Icon(Icons.add),
          label: const Text('Add Activity'),
        ),
        if (hasPlan && !activityManager.hasActiveActivity)
          ElevatedButton.icon(
            onPressed: activityManager.startPlan,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Plan'),
          ),
        if (hasPlan)
          TextButton.icon(
            onPressed: onCancelPlan,
            icon: const Icon(Icons.clear),
            label: const Text('Clear Plan'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }
}

class _PlannedActivityItem extends StatelessWidget {
  const _PlannedActivityItem({
    super.key,
    required this.planned,
    required this.isActive,
    required this.onRemove,
  });

  final PlannedActivity planned;
  final bool isActive;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: isActive
            ? const Icon(Icons.play_circle_fill)
            : const Icon(Icons.circle_outlined),
        title: Text(planned.activity.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(planned.targetDescription),
            if (planned.targetType != PlanTargetType.unlimited &&
                planned.progress > 0)
              LinearProgressIndicator(value: planned.progress),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: onRemove,
          color: Theme.of(context).colorScheme.error,
        ),
        isThreeLine:
            planned.targetType != PlanTargetType.unlimited &&
            planned.progress > 0,
      ),
    );
  }
}

/// Dialog for adding an activity to the planner.
class AddPlannedActivityDialog extends StatefulWidget {
  const AddPlannedActivityDialog({
    super.key,
    required this.activities,
    required this.character,
    required this.activityManager,
  });

  final List<Activity> activities;
  final Character character;
  final ActivityManager activityManager;

  @override
  State<AddPlannedActivityDialog> createState() =>
      _AddPlannedActivityDialogState();
}

class _AddPlannedActivityDialogState extends State<AddPlannedActivityDialog> {
  Activity? _selectedActivity;
  PlanTargetType _targetType = PlanTargetType.completions;
  final _targetController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    // Set the selected activity to the first one that meets requirements
    final availableActivities = widget.activities
        .where((a) => a.meetsRequirements(widget.character.stats))
        .toList();
    if (availableActivities.isNotEmpty) {
      _selectedActivity = availableActivities.first;
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Planned Activity'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityDropdown(),
            const SizedBox(height: 16),
            _buildTargetTypeSelector(),
            const SizedBox(height: 16),
            if (_targetType != PlanTargetType.unlimited)
              _buildTargetValueInput(),
            if (_targetType == PlanTargetType.unlimited)
              _buildUnlimitedWarning(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedActivity != null ? _addActivity : null,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildActivityDropdown() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Activity',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Activity>(
          value: _selectedActivity,
          isExpanded: true,
          isDense: true,
          items: widget.activities
              .where((a) => a.meetsRequirements(widget.character.stats))
              .map((activity) {
                final duration = widget.activityManager
                    .calculateActivityDuration(activity);
                return DropdownMenuItem(
                  value: activity,
                  child: Text(
                    '${activity.name} (${formatDurationCompact(duration)})',
                  ),
                );
              })
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedActivity = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTargetTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Type:'),
        const SizedBox(height: 8),
        SegmentedButton<PlanTargetType>(
          segments: const [
            ButtonSegment(
              value: PlanTargetType.completions,
              label: Text('Completions'),
              icon: Icon(Icons.repeat),
            ),
            ButtonSegment(
              value: PlanTargetType.inGameTime,
              label: Text('Time'),
              icon: Icon(Icons.timer),
            ),
            ButtonSegment(
              value: PlanTargetType.unlimited,
              label: Text('Unlimited'),
              icon: Icon(Icons.all_inclusive),
            ),
          ],
          selected: {_targetType},
          onSelectionChanged: (selected) {
            setState(() {
              _targetType = selected.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTargetValueInput() {
    final label = _targetType == PlanTargetType.completions
        ? 'Number of completions'
        : 'In-game time (seconds)';

    return TextField(
      controller: _targetController,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: _targetType == PlanTargetType.completions ? 'x' : 's',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }

  Widget _buildUnlimitedWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unlimited activities run until manually stopped. '
              'No activities can be added after this.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addActivity() {
    if (_selectedActivity == null) return;

    double targetValue = 0;
    if (_targetType != PlanTargetType.unlimited) {
      targetValue = double.tryParse(_targetController.text) ?? 1;
      if (targetValue <= 0) targetValue = 1;
    }

    final planned = PlannedActivity(
      activity: _selectedActivity!,
      targetType: _targetType,
      targetValue: targetValue,
    );

    Navigator.of(context).pop(planned);
  }
}

/// Confirmation dialog for cancelling the activity plan.
class CancelPlanDialog extends StatelessWidget {
  const CancelPlanDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Plan?'),
      content: const Text(
        'Are you sure you want to clear your activity plan? '
        'This will stop the current activity and remove all planned activities.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep Plan'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Clear Plan'),
        ),
      ],
    );
  }
}

/// Confirmation dialog when selecting a new activity while plan is active.
class SwitchActivityDialog extends StatelessWidget {
  const SwitchActivityDialog({super.key, required this.newActivity});

  final Activity newActivity;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Switch Activity?'),
      content: Text(
        'You have an active plan. Starting "${newActivity.name}" will cancel '
        'your current plan. Do you want to continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep Plan'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Switch Activity'),
        ),
      ],
    );
  }
}
