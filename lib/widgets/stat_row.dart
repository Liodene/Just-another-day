import 'package:flutter/material.dart';

/// Displays a single stat row with name, progress bar, and value.
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.name,
    required this.value,
    required this.color,
    this.maxValue = 100.0,
  });

  final String name;
  final double value;
  final Color color;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(name)),
          Expanded(
            child: Semantics(
              label: '$name: ${value.toStringAsFixed(1)} out of $maxValue',
              child: LinearProgressIndicator(
                value: (value / maxValue).clamp(0.0, 1.0),
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(value.toStringAsFixed(1), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
