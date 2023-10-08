import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dictionary.dart';

class RandomWordsFromDictionarySelector extends StatefulWidget {
  final Dictionary dictionary;
  final int maxNumberOfWords;
  final Function(int) onNumberOfWordsChanged;

  const RandomWordsFromDictionarySelector({
    super.key,
    required this.dictionary,
    required this.maxNumberOfWords,
    required this.onNumberOfWordsChanged,
  });

  @override
  State<RandomWordsFromDictionarySelector> createState() =>
      _RandomWordsFromDictionarySelectorState();
}

class _RandomWordsFromDictionarySelectorState
    extends State<RandomWordsFromDictionarySelector> {
  int numberOfWords = 1;
  late TextEditingController _textEditingController;
  final NumberFormat _numberFormat = NumberFormat('#,##0');
  bool isSelected = false;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _textEditingController.text = _numberFormat.format(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCheckbox(),
        if (isSelected) _buildSlider(),
      ],
    );
  }

  _buildCheckbox() {
    return CheckboxListTile(
      title: Text(widget.dictionary.name),
      value: isSelected,
      onChanged: (value) {
        setState(() {
          isSelected = value!;
          if (isSelected) {
            widget.onNumberOfWordsChanged(numberOfWords);
          } else {
            widget.onNumberOfWordsChanged(0);
          }
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSlider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Slider(
          value: numberOfWords.toDouble(),
          min: 1,
          max: widget.maxNumberOfWords.toDouble(),
          onChanged: (newValue) {
            setState(() {
              numberOfWords = newValue.toInt();
              _textEditingController.text = _numberFormat.format(newValue);
              widget.onNumberOfWordsChanged(numberOfWords);
            });
          },
        ),
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
                if (val == null || val < 1 || val > widget.maxNumberOfWords) {
                  if (val != null) {
                    val = min(val, widget.maxNumberOfWords);
                    val = max(val, 1);
                  } else {
                    val = 1;
                  }
                  _textEditingController.text = _numberFormat.format(val);
                }
                numberOfWords = val;
                widget.onNumberOfWordsChanged(numberOfWords);
              });
            },
          ),
        ),
      ],
    );
  }
}
