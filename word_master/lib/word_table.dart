import 'package:flutter/material.dart';
import 'package:realm/realm.dart';

import 'dictionary_entry.dart';

class WordTable extends StatelessWidget {
  final RealmResults<DictionaryEntry> entries;

  const WordTable({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Table'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final item = entries[index];
        return ListTile(
          title: Text(item.wordOrPhrase),
        );
      },
    );
  }
}
