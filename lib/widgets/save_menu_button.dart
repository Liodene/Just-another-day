import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/save_manager.dart';

/// Shared actions for save, export, import, and reset dialogs.
class SaveMenuActions {
  const SaveMenuActions({
    required this.saveManager,
    required this.onImport,
    required this.onReset,
  });

  final SaveManager saveManager;
  final void Function(GameSaveData) onImport;
  final VoidCallback onReset;

  Future<void> handleSelection(BuildContext context, String value) async {
    switch (value) {
      case 'save':
        await _handleSave(context);
      case 'export':
        await _handleExport(context);
      case 'import':
        await _handleImport(context);
      case 'reset':
        await _handleReset(context);
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    final success = await saveManager.save();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Game saved!' : 'Failed to save game'),
        backgroundColor: success
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    final jsonString = saveManager.exportSave();
    if (jsonString == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to export save'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: jsonString));

    if (!context.mounted) return;

    // Show dialog with the save data
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Save'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your save data has been copied to the clipboard. '
                'You can also copy it from below:',
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonString,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonString));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('Copy Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext context) async {
    final controller = TextEditingController();

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Save'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paste your save data below:'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Paste JSON save data here...',
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Try to paste from clipboard
                final clipboardData = await Clipboard.getData('text/plain');
                if (clipboardData?.text != null) {
                  controller.text = clipboardData!.text!;
                }
              },
              child: const Text('Paste from Clipboard'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (result == null || result.isEmpty) return;

      final saveData = saveManager.importSave(result);

      if (!context.mounted) return;

      if (saveData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid save data'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Confirm import
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Import'),
          content: Text(
            'This will replace your current game with a save from '
            '${saveData.savedAt.toLocal()} (${saveData.timezone}).\n\n'
            'Day ${saveData.gameTime.dayCount}, '
            'Total completions: ${saveData.character.totalCompletions}\n\n'
            'Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirm ?? false) {
        onImport(saveData);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Save imported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _handleReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700]),
            const SizedBox(width: 8),
            const Text('Reset Save'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your progress and start a new game.\n\n'
          'This action cannot be undone!\n\n'
          'Are you sure you want to reset?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      onReset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save reset successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

/// A menu button that provides save, export, import, and reset functionality.
class SaveMenuButton extends StatelessWidget {
  /// Creates a new [SaveMenuButton].
  const SaveMenuButton({
    required this.saveManager,
    required this.onImport,
    required this.onReset,
    super.key,
  });

  /// The save manager instance.
  final SaveManager saveManager;

  /// Callback when a save is imported successfully.
  final void Function(GameSaveData) onImport;

  /// Callback when the save is reset.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final actions = SaveMenuActions(
      saveManager: saveManager,
      onImport: onImport,
      onReset: onReset,
    );

    return PopupMenuButton<String>(
      icon: const Icon(Icons.save),
      tooltip: 'Save Menu',
      onSelected: (value) => actions.handleSelection(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'save',
          child: ListTile(
            leading: Icon(Icons.save),
            title: Text('Save Game'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.upload),
            title: Text('Export Save'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'import',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text('Import Save'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'reset',
          child: ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red[700]),
            title: Text('Reset Save', style: TextStyle(color: Colors.red[700])),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
