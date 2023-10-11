import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:word_master/word_collection_data.dart';

class OldWordCollectionCard extends StatelessWidget {
  final WordCollectionData oldWordCollection;
  final Function(WordCollectionData) onTap;
  final Function(WordCollectionData) onDismissed;
  final double widthFactor;
  final NumberFormat _numberFormat = NumberFormat('#,##0');
  final Future<bool?> Function(DismissDirection, BuildContext, String)
      confirmDismiss;

  OldWordCollectionCard({
    super.key,
    required this.onTap,
    this.widthFactor = 1.0,
    required this.onDismissed,
    required this.oldWordCollection,
    required this.confirmDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dismissible(
        key: Key(ObjectKey(oldWordCollection).toString()),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) {
          return confirmDismiss(
              direction,
              context,
              oldWordCollection.name.isNotEmpty
                  ? oldWordCollection.name
                  : "Untitled Word Collection");
        },
        onDismissed: (direction) {
          onDismissed(oldWordCollection);
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
          onTap: () => onTap(oldWordCollection),
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    final DateTime createdOn = oldWordCollection.createdOn;
    List<Widget> widgets = [];
    if (oldWordCollection.name.isNotEmpty) {
      widgets.add(Text(oldWordCollection.name,
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
        "with ${_numberFormat.format(oldWordCollection.words.length)} entries"));
    return widgets;
  }
}
