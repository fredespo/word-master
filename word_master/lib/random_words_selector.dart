import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:word_master/dictionary.dart';
import 'package:word_master/random_words_from_dictionary_selector.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_entry.dart';

class RandomWordsSelector extends StatelessWidget {
  final RealmResults<Dictionary> dictionaries;
  final WordCollection? existingWordCollection;
  final Realm db;
  final Function(Dictionary, int) onNumEntriesChanged;

  const RandomWordsSelector({
    super.key,
    required this.dictionaries,
    this.existingWordCollection,
    required this.db,
    required this.onNumEntriesChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<Dictionary> dictionaries = this.dictionaries.toList();
    List<int> maxEntriesToAdd = getMaxEntriesToAdd(dictionaries);
    Map<Dictionary, int> maxEntriesToAddPerDict = {};
    for (var i = 0; i < dictionaries.length; i++) {
      var max = maxEntriesToAdd[i];
      if (max > 0) {
        maxEntriesToAddPerDict[dictionaries[i]] = max;
      }
    }
    List<Widget> dictSelectors = [];
    for (var dict in maxEntriesToAddPerDict.keys) {
      dictSelectors.add(RandomWordsFromDictionarySelector(
        dictionary: dict,
        maxNumberOfWords: maxEntriesToAddPerDict[dict]!,
        onNumberOfWordsChanged: (int value) {
          onNumEntriesChanged(dict, value);
        },
      ));
    }
    return Column(
      children: [
        const Text(
          'Dictionaries',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 300,
          width: 300,
          child: ListView(
            children: dictSelectors,
          ),
        ),
      ],
    );
  }

  List<int> getMaxEntriesToAdd(List<Dictionary> dictionaries) {
    return dictionaries.map((e) {
      if (existingWordCollection == null) {
        return e.size;
      }
      var existingEntriesFromThisDict = db.all<WordCollectionEntry>().query(
          "dictionaryId = '${e.id}' AND wordCollectionId = '${existingWordCollection!.id}'");
      return e.size - existingEntriesFromThisDict.length;
    }).toList();
  }
}
