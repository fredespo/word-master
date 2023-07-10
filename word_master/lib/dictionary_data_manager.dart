import 'package:flutter/material.dart';
import 'package:realm/realm.dart';

import 'dictionary_data_importer.dart';
import 'dictionary_entry.dart';

class DictionaryDataManager extends StatelessWidget {
  final Realm db;

  const DictionaryDataManager({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dictionary Data'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DictionaryDataImporter(db: db),
            const SizedBox(height: 20),
            _buildReadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadButton() {
    return ElevatedButton(
      onPressed: () async {
        var all = db.all<DictionaryEntry>();
        for (var entry in all) {
          print(entry.wordOrPhrase);
          print(entry.definitions);
        }
      },
      child: const Text('Read'),
    );
  }
}
