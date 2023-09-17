import 'package:flutter/material.dart';

class DictionaryCreationDialog extends StatefulWidget {
  final Function(String) onCreated;

  const DictionaryCreationDialog({
    super.key,
    required this.onCreated,
  });

  @override
  State<DictionaryCreationDialog> createState() =>
      _DictionaryCreationDialogState();
}

class _DictionaryCreationDialogState extends State<DictionaryCreationDialog> {
  String name = '';

  @override
  Widget build(BuildContext context) {
    // an alert dialog with a text field to enter the name
    // of the new dictionary
    return AlertDialog(
      title: const Text('Create a new dictionary'),
      content: _buildContent(),
      actions: [
        _buildCancelButton(),
        _buildCreateButton(),
      ],
    );
  }

  Widget _buildContent() {
    return TextField(
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Name',
      ),
      onChanged: (value) {
        setState(() {
          name = value;
        });
      },
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text('Cancel'),
    );
  }

  Widget _buildCreateButton() {
    return Opacity(
      opacity: _isValid() ? 1.0 : 0.5,
      child: ElevatedButton(
        onPressed: () => _isValid() ? _createNewDictionary() : null,
        child: const Text('Create'),
      ),
    );
  }

  bool _isValid() {
    return name.trim().isNotEmpty;
  }

  void _createNewDictionary() {
    Navigator.of(context).pop();
    widget.onCreated(name.trim());
  }
}
