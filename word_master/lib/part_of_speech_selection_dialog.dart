import 'package:flutter/material.dart';
import 'package:word_master/const/parts_of_speech.dart';

class PartOfSpeechSelectionDialog extends StatefulWidget {
  final Function(String) onConfirmed;
  final List<String> alreadySelected;

  const PartOfSpeechSelectionDialog({
    super.key,
    required this.onConfirmed,
    required this.alreadySelected,
  });

  @override
  State<PartOfSpeechSelectionDialog> createState() =>
      _PartOfSpeechSelectionDialogState();
}

class _PartOfSpeechSelectionDialogState
    extends State<PartOfSpeechSelectionDialog> {
  late String selectedDropdownValue;

  @override
  void initState() {
    super.initState();
    selectedDropdownValue = PartsOfSpeech.all
        .firstWhere((element) => !widget.alreadySelected.contains(element));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select a part of speech'),
      content: _buildDropdown(),
      actions: [
        _buildCancelButton(),
        _buildOkButton(),
      ],
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

  Widget _buildOkButton() {
    return ElevatedButton(
      onPressed: () {
        widget.onConfirmed(selectedDropdownValue);
        Navigator.of(context).pop();
      },
      child: const Text('OK'),
    );
  }

  Widget _buildDropdown() {
    return DropdownButton<String>(
      value: selectedDropdownValue,
      items: _buildDropdownItems(),
      isExpanded: true,
      onChanged: _onDropdownChanged,
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    final unselectedItems = PartsOfSpeech.all
        .where((item) => !widget.alreadySelected.contains(item));

    return unselectedItems.map(
      (e) {
        Widget txt = Text(
          e,
          textAlign: TextAlign.center,
        );
        return DropdownMenuItem(
          value: e,
          child: Center(
            child: SizedBox(
              width: 100,
              child: txt,
            ),
          ),
        );
      },
    ).toList();
  }

  void _onDropdownChanged(String? value) {
    setState(() {
      selectedDropdownValue = value!;
    });
  }
}
