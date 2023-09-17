import 'package:flutter/material.dart';

class DictionaryDefinitionCreatorSection extends StatefulWidget {
  final String partOfSpeech;
  final List<String>? definitionsToEdit;
  final Function(List<String>) onDefinitionsChanged;

  const DictionaryDefinitionCreatorSection({
    super.key,
    required this.partOfSpeech,
    this.definitionsToEdit,
    required this.onDefinitionsChanged,
  });

  @override
  State<DictionaryDefinitionCreatorSection> createState() =>
      _DictionaryDefinitionCreatorSectionState();
}

class _DictionaryDefinitionCreatorSectionState
    extends State<DictionaryDefinitionCreatorSection> {
  List<String> defs = [];
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.definitionsToEdit != null) {
      defs = widget.definitionsToEdit!;
      for (var def in widget.definitionsToEdit!) {
        controllers.add(TextEditingController(text: def));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: Border.all(color: Colors.grey),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildTitle(),
            _buildDefinitionsInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.partOfSpeech,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDefinitionsInput() {
    List<Widget> children = [];
    for (int i = 0; i < defs.length; i++) {
      children.add(_buildDefinitionInput(i));
    }
    children.add(_buildAddDefinitionButton());
    return Column(
      children: children,
    );
  }

  Widget _buildDefinitionInput(int i) {
    return Row(
      children: [
        Text("${i + 1}."),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Definition',
            ),
            maxLines: null,
            controller: controllers[i],
            onChanged: (value) {
              setState(() {
                defs[i] = value;
                widget.onDefinitionsChanged(defs);
              });
            },
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              defs.removeAt(i);
              controllers.removeAt(i);
              widget.onDefinitionsChanged(defs);
            });
          },
          icon: const Icon(Icons.delete),
        ),
      ],
    );
  }

  Widget _buildAddDefinitionButton() {
    return IconButton(
      onPressed: () {
        setState(() {
          defs.add('');
          controllers.add(TextEditingController());
          widget.onDefinitionsChanged(defs);
        });
      },
      icon: const Icon(Icons.add),
    );
  }
}
