import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realm/realm.dart';

import 'dictionary.dart';

class WordCollectionCreator extends StatefulWidget {
  final Function(String, Dictionary, int) onCreate;
  final RealmResults<Dictionary> dictionaries;

  const WordCollectionCreator({
    super.key,
    required this.onCreate,
    required this.dictionaries,
  });

  @override
  State<WordCollectionCreator> createState() => _WordCollectionCreatorState();
}

class _WordCollectionCreatorState extends State<WordCollectionCreator> {
  String name = '';
  int numberOfWords = 1;
  int maxNumberOfWords = 1;
  Dictionary? selectedDictionary;
  late TextEditingController _textEditingController;
  final NumberFormat _numberFormat = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _textEditingController.text = _numberFormat.format(0);
  }

  @override
  Widget build(BuildContext context) {
    return widget.dictionaries.isEmpty ||
            widget.dictionaries.every((element) => element.size == 0)
        ? AlertDialog(
            title: const Text('No words found'),
            content: const Text('Please add or import dictionary data first.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          )
        : AlertDialog(
            title: const Text('Create a new collection'),
            content: IntrinsicHeight(
              child: Column(children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      name = value;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dictionary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildDictionariesSelection(),
                const SizedBox(height: 20),
                const Text(
                  'Number of words',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IgnorePointer(
                  ignoring: selectedDictionary == null,
                  child: _buildSlider(),
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedDictionary != null
                    ? () {
                        Navigator.of(context).pop();
                        widget.onCreate(
                            name, selectedDictionary!, numberOfWords);
                      }
                    : null,
                child: const Text('Create'),
              ),
            ],
          );
  }

  Widget _buildDictionariesSelection() {
    // list of radio buttons
    return Column(
      children: widget.dictionaries.map((dictionary) {
        return RadioListTile<Dictionary>(
          title: Text(dictionary.name),
          value: dictionary,
          groupValue: selectedDictionary,
          onChanged: (Dictionary? value) {
            setState(() {
              selectedDictionary = value;
              maxNumberOfWords = selectedDictionary?.size ?? 1;
              numberOfWords = min(numberOfWords, maxNumberOfWords);
              _textEditingController.text = _numberFormat
                  .format(selectedDictionary == null ? 0 : numberOfWords);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSlider() {
    return Row(
      children: [
        Slider(
          value: numberOfWords.toDouble(),
          min: 1,
          max: maxNumberOfWords.toDouble(),
          onChanged: (newValue) {
            setState(() {
              numberOfWords = newValue.toInt();
              _textEditingController.text = _numberFormat.format(newValue);
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              child: TextField(
                controller: _textEditingController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none, // Remove underline
                ),
                onChanged: (newValue) {
                  setState(() {
                    int? val = int.tryParse(newValue);
                    if (val == null || val < 1 || val > maxNumberOfWords) {
                      if (val != null) {
                        val = min(val, maxNumberOfWords);
                        val = max(val, 1);
                      } else {
                        val = 1;
                      }
                      _textEditingController.text = _numberFormat.format(val);
                    }
                    numberOfWords = val;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
