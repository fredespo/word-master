import 'package:flutter/material.dart';

class PageSelectionDialog extends StatefulWidget {
  final Function(List<int>) onConfirmed;

  const PageSelectionDialog({
    super.key,
    required this.onConfirmed,
  });

  @override
  State<PageSelectionDialog> createState() => _PageSelectionDialogState();
}

class _PageSelectionDialogState extends State<PageSelectionDialog> {
  String input = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select pages'),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Pages (ex: 1,2,5,6)',
          ),
          onChanged: (value) => input = value,
        ),
      ),
      actions: [
        _buildCancelButton(context),
        _buildOkButton(context),
      ],
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      child: const Text('Cancel'),
    );
  }

  Widget _buildOkButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final pages = input
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .where((element) => element != null)
            .map((e) => e!)
            .toList();
        widget.onConfirmed(pages);
        Navigator.of(context).pop();
      },
      child: const Text('OK'),
    );
  }
}
