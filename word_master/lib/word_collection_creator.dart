import 'package:flutter/material.dart';
import 'package:word_master/slider_with_value.dart';

class WordCollectionCreator extends StatefulWidget {
  final Function(String, int) onCreate;

  const WordCollectionCreator({super.key, required this.onCreate});

  @override
  State<WordCollectionCreator> createState() => _WordCollectionCreatorState();
}

class _WordCollectionCreatorState extends State<WordCollectionCreator> {
  String name = '';
  int numberOfWords = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          const Text('Number of words:', style: TextStyle(fontSize: 16)),
          SliderWithValue(
            min: 1,
            max: 350000,
            onChanged: (int value) {
              setState(() {
                numberOfWords = value;
              });
            },
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
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCreate(name, numberOfWords);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
