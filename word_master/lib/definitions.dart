import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';

import 'dictionary_entry.dart';

class Definitions extends StatelessWidget {
  final String? wordOrPhrase;
  final String? dictionaryId;
  final DictionaryEntry? entry;
  final Realm? db;

  const Definitions({
    super.key,
    this.entry,
    this.wordOrPhrase,
    this.dictionaryId,
    this.db,
  }) : assert(
          (db != null && wordOrPhrase != null && dictionaryId != null) ||
              entry != null,
          'Either wordOrPhrase and dictionaryId must not be null or entry must not be null',
        );

  @override
  Widget build(BuildContext context) {
    DictionaryEntry dictionaryEntry;
    if (entry == null) {
      try {
        dictionaryEntry = db!
            .all<DictionaryEntry>()
            .query("dictionaryId == '$dictionaryId'")
            .query('wordOrPhrase == "$wordOrPhrase"')
            .first;
      } catch (e) {
        return const Text('No definitions found');
      }
    } else {
      dictionaryEntry = entry!;
    }

    String definitions = dictionaryEntry.definitions;
    Map<String, dynamic> jsonMap = jsonDecode(definitions);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: jsonMap.keys.map((key) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...List<Widget>.generate(
                jsonMap[key].length,
                (index) => Text('${index + 1}. ${jsonMap[key][index]}'),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
