import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:word_master/const/parts_of_speech.dart';
import 'package:word_master/dictionary_definition_creator_section.dart';
import 'package:word_master/dictionary_entry.dart';
import 'package:word_master/part_of_speech_selection_dialog.dart';

class DictionaryDefinitionCreator extends StatefulWidget {
  final Function(Map<String, List<String>>) onDefinitionsChanged;
  final DictionaryEntry? entryToEdit;
  final Map<String, List<String>>? existingDefinitions;

  const DictionaryDefinitionCreator({
    super.key,
    required this.onDefinitionsChanged,
    this.entryToEdit,
    this.existingDefinitions,
  });

  @override
  State<DictionaryDefinitionCreator> createState() =>
      _DictionaryDefinitionCreatorState();
}

class _DictionaryDefinitionCreatorState
    extends State<DictionaryDefinitionCreator> {
  List<Widget> definitionWidgets = [];
  Map<String, List<String>> definitions = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingDefinitions != null &&
        widget.existingDefinitions!.isNotEmpty) {
      definitions = widget.existingDefinitions!;
      definitions.forEach((partOfSpeech, defs) {
        definitionWidgets.add(_buildDefinitionInput(partOfSpeech));
      });
    } else if (widget.entryToEdit != null) {
      Map<String, dynamic> defs = jsonDecode(widget.entryToEdit!.definitions);
      defs.forEach((partOfSpeech, defs) {
        definitions[partOfSpeech] = List<String>.from(defs);
      });
      definitions.forEach((partOfSpeech, defs) {
        definitionWidgets.add(_buildDefinitionInput(partOfSpeech));
      });
    } else if (definitions.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPartOfSpeechSelectionDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.height * 0.6,
      child: ListView(
        children: [
          ...definitionWidgets,
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildAddDefinitionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDefinitionButton() {
    return Opacity(
      opacity: PartsOfSpeech.all.length != definitions.length ? 1.0 : 0.5,
      child: ElevatedButton(
        onPressed: PartsOfSpeech.all.length != definitions.length
            ? () {
                _showPartOfSpeechSelectionDialog();
              }
            : null,
        child: const Text('New Section'),
      ),
    );
  }

  void _showPartOfSpeechSelectionDialog() {
    showDialog(
        context: context,
        builder: (_) => PartOfSpeechSelectionDialog(
              alreadySelected: definitions.keys.toList(),
              onConfirmed: (String partOfSpeech) {
                setState(() {
                  definitionWidgets.add(_buildDefinitionInput(partOfSpeech));
                  definitions[partOfSpeech] = [];
                  widget.onDefinitionsChanged(definitions);
                });
              },
            ));
  }

  Widget _buildDefinitionInput(String partOfSpeech) {
    return DictionaryDefinitionCreatorSection(
      partOfSpeech: partOfSpeech,
      definitionsToEdit: definitions[partOfSpeech],
      onDefinitionsChanged: (List<String> defs) {
        definitions[partOfSpeech] = defs;
        widget.onDefinitionsChanged(definitions);
      },
    );
  }
}
