import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/dictionary_entry.dart';

import 'dictionary.dart';
import 'dictionary_definition_creator.dart';

class DictionaryEntryCreationDialog extends StatefulWidget {
  final Realm db;
  final String dictionaryId;
  final DictionaryEntry? entryToEdit;

  const DictionaryEntryCreationDialog({
    super.key,
    required this.db,
    required this.dictionaryId,
    this.entryToEdit,
  });

  @override
  State<DictionaryEntryCreationDialog> createState() =>
      _DictionaryEntryCreationDialogState();
}

class _DictionaryEntryCreationDialogState
    extends State<DictionaryEntryCreationDialog> {
  String wordOrPhrase = '';
  Map<String, List<String>> definitions = {};
  int page = 1;

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      wordOrPhrase = widget.entryToEdit!.wordOrPhrase;
      Map<String, dynamic> defs = jsonDecode(widget.entryToEdit!.definitions);
      defs.forEach((partOfSpeech, defs) {
        definitions[partOfSpeech] = List<String>.from(defs);
      });
      page = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(page == 1
          ? 'Create a new entry'
          : 'Add definitions for "$wordOrPhrase"'),
      content: _buildContent(),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (page == 2) _buildEditWordOrPhraseButton(),
            const Spacer(),
            _buildCancelButton(),
            const SizedBox(width: 20),
            _buildContinueButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildEditWordOrPhraseButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          page = 1;
        });
      },
      child: Text('Edit ${wordOrPhrase.contains(' ') ? 'phrase' : 'word'}'),
    );
  }

  Widget _buildContent() {
    switch (page) {
      case 1:
        return _buildWordOrPhraseInput();

      case 2:
        return _buildDefinitionsInput();
    }
    return const Placeholder();
  }

  Widget _buildWordOrPhraseInput() {
    return TextFormField(
      initialValue: wordOrPhrase,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Word or phrase',
      ),
      onChanged: (value) {
        setState(() {
          wordOrPhrase = value.trim();
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

  Widget _buildContinueButton() {
    return Opacity(
      opacity: _isValid() ? 1.0 : 0.5,
      child: ElevatedButton(
        onPressed: () =>
            _isValid() ? _continue() : (page == 1 ? _checkForDupe() : null),
        child: Text(page == 1 ? 'Continue' : 'Save'),
      ),
    );
  }

  bool _isValid() {
    switch (page) {
      case 1:
        if (wordOrPhrase.isEmpty) {
          return false;
        }

        if (widget.entryToEdit == null) {
          return !_isDuplicate();
        } else {
          return wordOrPhrase == widget.entryToEdit!.wordOrPhrase ||
              !_isDuplicate();
        }

      case 2:
        return definitions.isNotEmpty &&
            definitions.values.every(
                (e) => e.isNotEmpty && e.every((e2) => e2.trim().isNotEmpty));
    }
    return false;
  }

  void _continue() {
    switch (page) {
      case 1:
        setState(() {
          page++;
        });
        break;

      case 2:
        _save();
        break;
    }
  }

  Widget _buildDefinitionsInput() {
    return DictionaryDefinitionCreator(
      entryToEdit: widget.entryToEdit,
      existingDefinitions: definitions.isNotEmpty ? definitions : null,
      onDefinitionsChanged: (defs) {
        setState(() {
          definitions = defs;
        });
      },
    );
  }

  void _save() {
    widget.db.write(
      () {
        if (widget.entryToEdit != null) {
          widget.entryToEdit!.wordOrPhrase = wordOrPhrase;
          widget.entryToEdit!.definitions = jsonEncode(definitions);
        } else {
          DictionaryEntry entry = DictionaryEntry(
              widget.dictionaryId, wordOrPhrase, jsonEncode(definitions));
          widget.db.add(entry);
          widget.db.find<Dictionary>(widget.dictionaryId)!.size++;
        }
      },
    );
    Navigator.of(context).pop();
  }

  _isDuplicate() {
    return widget.db
        .all<DictionaryEntry>()
        .query("wordOrPhrase == \$0", [wordOrPhrase])
        .query("dictionaryId == '${widget.dictionaryId}'")
        .isNotEmpty;
  }

  void _checkForDupe() {
    if (_isDuplicate()) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Duplicate Entry Detected'),
            content: const Text(
                'This word or phrase already exists in this dictionary.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
}
