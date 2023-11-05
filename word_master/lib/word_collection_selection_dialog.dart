import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:word_master/word_collection.dart';

class WordCollectionSelectionDialog extends StatelessWidget {
  final List<WordCollection> wordCollections;
  final Function(WordCollection) onSelect;
  final Function() onCreateNewCollection;

  const WordCollectionSelectionDialog({
    super.key,
    required this.wordCollections,
    required this.onSelect,
    required this.onCreateNewCollection,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open in new tab', textAlign: TextAlign.center),
      backgroundColor: Colors.grey.shade200,
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        width: 400,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: wordCollections.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => onSelect(wordCollections[index]),
                    child: Card(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _buildCardBody(wordCollections[index]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onCreateNewCollection,
              child: const Text('Create new collection'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardBody(WordCollection wordCollection) {
    final DateTime createdOn = wordCollection.createdOn;
    final NumberFormat numberFormat = NumberFormat('#,##0');
    List<Widget> widgets = [];
    if (wordCollection.name.isNotEmpty) {
      widgets.add(Text(wordCollection.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          )));
      widgets.add(const SizedBox(height: 8));
    }
    widgets.add(Text(
        "Created on ${createdOn.month}/${createdOn.day}/${createdOn.year}"));
    widgets.add(const SizedBox(height: 8));
    widgets
        .add(Text("with ${numberFormat.format(wordCollection.size)} entries"));
    return widgets;
  }
}
