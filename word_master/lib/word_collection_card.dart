import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:word_master/word_collection.dart';

class WordCollectionCard extends StatelessWidget {
  final WordCollection wordCollection;
  final Function(WordCollection) onTap;
  final Function(WordCollection) onDismissed;
  final double widthFactor;
  final NumberFormat _numberFormat = NumberFormat('#,##0');
  final Future<bool?> Function(DismissDirection, BuildContext, String)
      confirmDismiss;

  WordCollectionCard({
    super.key,
    required this.wordCollection,
    required this.onTap,
    this.widthFactor = 1.0,
    required this.onDismissed,
    required this.confirmDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dismissible(
        key: Key(ObjectKey(wordCollection).toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) {
          return confirmDismiss(
              direction,
              context,
              wordCollection.name.isNotEmpty
                  ? wordCollection.name
                  : "Untitled Word Collection");
        },
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
    widgets
        .add(Text("with ${_numberFormat.format(wordCollection.size)} entries"));
    return widgets;
  }
}
