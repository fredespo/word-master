import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:realm/realm.dart';

import 'dictionary_data_importer.dart';
import 'dictionary_entry.dart';

class DictionaryDataManager extends StatefulWidget {
  final Realm db;

  const DictionaryDataManager({super.key, required this.db});

  @override
  State<DictionaryDataManager> createState() => _DictionaryDataManagerState();
}

class _DictionaryDataManagerState extends State<DictionaryDataManager> {
  final NumberFormat _numberFormat = NumberFormat('#,##0');
  num _entryCount = 0;

  @override
  void initState() {
    super.initState();
    _entryCount = widget.db.all<DictionaryEntry>().length;
  }

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
            Text(
              "You have ${_numberFormat.format(_entryCount)} entries in your dictionary.",
            ),
            const SizedBox(height: 20),
            DictionaryDataImporter(
              db: widget.db,
              onImportComplete: (count) {
                setState(() {
                  _entryCount = count;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
