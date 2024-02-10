import 'dart:collection';
import 'dart:math';

import 'package:realm/realm.dart';
import 'package:word_master/word_collection.dart';
import 'package:word_master/word_collection_entry.dart';

class WordCollectionEntryMover {
  Realm db;
  int batchSize;
  Duration delayBetweenBatches;
  final _linkedList = LinkedList<LinkedListNode>();
  final Map<int, LinkedListNode> _nodePerId = {};
  final Random rng = Random();

  WordCollectionEntryMover(this.db, this.batchSize, this.delayBetweenBatches);

  void init(WordCollection wordCollection) {
    _linkedList.clear();
    _nodePerId.clear();
    var entries = db
        .all<WordCollectionEntry>()
        .query("wordCollectionId == '${wordCollection.id}'")
        .query("TRUEPREDICATE SORT(id ASC)")
        .toList();
    for (var entry in entries) {
      var node = LinkedListNode(entry);
      _linkedList.add(node);
      _nodePerId[entry.id] = node;
    }
  }

  Future moveToRandPositions(List<int> ids) async {
    for (var i = 0; i < ids.length; i += batchSize) {
      for (var j = i; j < min(i + batchSize, ids.length); j++) {
        var id = ids[j];
        var node = _nodePerId[id];
        if (node != null) {
          _linkedList.remove(node);
          _nodePerId.remove(id);
          insertBeforeRandomNode(node);
        }
      }
      await Future.delayed(delayBetweenBatches);
    }
    await finalize();
  }

  Future finalize() async {
    var id = 1;
    Iterator<LinkedListNode> it = _linkedList.iterator;
    for (int i = 0; i < _linkedList.length; i += batchSize) {
      db.write(() {
        for (var j = 0;
            j < batchSize && j < _linkedList.length && it.moveNext();
            j++) {
          var node = it.current;
          node.wordCollectionEntry.id = id++;
        }
      });
      await Future.delayed(delayBetweenBatches);
    }
  }

  void insertBeforeRandomNode(LinkedListNode node) {
    var randId = rng.nextInt(_linkedList.length + 1);
    while (!_nodePerId.containsKey(randId)) {
      randId = rng.nextInt(_linkedList.length + 1);
    }
    _nodePerId[randId]!.insertBefore(node);
  }
}

class LinkedListNode extends LinkedListEntry<LinkedListNode> {
  final WordCollectionEntry wordCollectionEntry;

  LinkedListNode(this.wordCollectionEntry);
}
