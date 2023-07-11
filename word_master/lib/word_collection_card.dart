import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:word_master/word_collection_data.dart';

class WordCollectionCard extends StatelessWidget {
  final WordCollectionData wordCollection;
  final Function(WordCollectionData) onTap;
  final Function(WordCollectionData) onDismissed;
  final double widthFactor;
  final NumberFormat _numberFormat = NumberFormat('#,##0');

  WordCollectionCard({
    super.key,
    required this.wordCollection,
    required this.onTap,
    this.widthFactor = 1.0,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dismissible(
        key: Key(ObjectKey(wordCollection).toString()),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          onDismissed(wordCollection);
        },
        background: Container(
          color: Colors.red,
          child: const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
          ),
        ),
        child: GestureDetector(
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildBody(),
                ),
              ),
            ),
          ),
          onTap: () => onTap(wordCollection),
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    final DateTime createdOn = wordCollection.createdOn;
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
    widgets.add(Text(
        "with ${_numberFormat.format(wordCollection.words.length)} entries"));
    return widgets;
  }
}
