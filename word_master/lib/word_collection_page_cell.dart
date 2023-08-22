import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class WordCollectionPageCell extends StatefulWidget {
  final String wordOrPhrase;
  final Color bgColor;
  final bool isFavorite;
  final Function(String) showDefinitions;
  final Function(String) onMarkedFavorite;
  final Function(String) onUnmarkedFavorite;

  const WordCollectionPageCell({
    super.key,
    required this.wordOrPhrase,
    required this.bgColor,
    required this.isFavorite,
    required this.showDefinitions,
    required this.onMarkedFavorite,
    required this.onUnmarkedFavorite,
  });

  @override
  State<WordCollectionPageCell> createState() => _WordCollectionPageCellState();
}

class _WordCollectionPageCellState extends State<WordCollectionPageCell> {
  late bool isFavorite;

  @override
  void initState() {
    isFavorite = widget.isFavorite;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.bgColor,
      ),
      child: SizedBox(
        height: 50,
        child: InkWell(
          onLongPress: () => _toggleIsFavorite(),
          onTap: () => widget.showDefinitions(widget.wordOrPhrase),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Stack(
              children: [
                Center(child: _buildText()),
                if (isFavorite) _buildHighlight(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    final fontWeight = isFavorite ? FontWeight.bold : FontWeight.normal;
    return AutoSizeText(
      textAlign: TextAlign.center,
      widget.wordOrPhrase,
      maxLines: 2,
      minFontSize: 8,
      maxFontSize: 12,
      style: TextStyle(fontWeight: fontWeight),
    );
  }

  Widget _buildHighlight() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 35,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(112, 255, 230, 0),
              Color.fromRGBO(255, 230, 0, 0.09)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  void _toggleIsFavorite() {
    setState(() {
      isFavorite = !isFavorite;
      if (isFavorite) {
        widget.onMarkedFavorite(widget.wordOrPhrase);
      } else {
        widget.onUnmarkedFavorite(widget.wordOrPhrase);
      }
    });
  }
}
