import 'package:flutter/material.dart';

class WordCollectionTabsTitle extends StatefulWidget {
  final ValueNotifier<int> selectedCount;
  final Function() onViewAll;

  const WordCollectionTabsTitle({
    super.key,
    required this.selectedCount,
    required this.onViewAll,
  });

  @override
  State<WordCollectionTabsTitle> createState() =>
      _WordCollectionTabsTitleState();
}

class _WordCollectionTabsTitleState extends State<WordCollectionTabsTitle> {
  int selectedCount = 0;

  @override
  void initState() {
    super.initState();
    widget.selectedCount.addListener(onSelectedCountChange);
  }

  @override
  Widget build(BuildContext context) {
    return selectedCount > 0
        ? _buildMultiSelectTitle(selectedCount)
        : _buildNormalTitle();
  }

  Widget _buildMultiSelectTitle(int numSelected) {
    return Text("$numSelected selected");
  }

  Widget _buildNormalTitle() {
    return Row(
      children: [
        const Text('Collections'),
        const SizedBox(width: 20),
        _buildViewAllButton(),
      ],
    );
  }

  void onSelectedCountChange() {
    setState(() {
      selectedCount = widget.selectedCount.value;
    });
  }

  _buildViewAllButton() {
    return TextButton(
      onPressed: widget.onViewAll,
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
        backgroundColor: Colors.white,
      ),
      child: const Text(
        "All",
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.selectedCount.removeListener(onSelectedCountChange);
    super.dispose();
  }
}
