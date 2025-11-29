// lib/widgets/lesson_form.dart

import 'package:flutter/material.dart';
import '../backend_data/lesson_data.dart';

class LessonForm extends StatefulWidget {
  final SectionNotes initialData;
  final ValueChanged<SectionNotes> onChanged;

  const LessonForm({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<LessonForm> createState() => _LessonFormState();
}

class _LessonFormState extends State<LessonForm> {
  late TextEditingController _topicCtrl;
  late TextEditingController _passageCtrl;
  late List<ContentBlock> _blocks;

  // Controllers for each editable block (prevents recreation bugs)
  final Map<int, List<TextEditingController>> _listControllers = {};

  @override
  void initState() {
    super.initState();
    _topicCtrl = TextEditingController(text: widget.initialData.topic);
    _passageCtrl = TextEditingController(text: widget.initialData.biblePassage);
    _blocks = List.from(widget.initialData.blocks);

    _topicCtrl.addListener(_notifyParent);
    _passageCtrl.addListener(_notifyParent);

    // Initialize controllers for existing lists
    _initListControllers();
  }

  void _initListControllers() {
    for (int i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      if (block.items != null) {
        _listControllers[i] = block.items!
            .map((item) => TextEditingController(text: item))
            .toList();
      }
    }
  }

  void _notifyParent() {
    widget.onChanged(SectionNotes(
      topic: _topicCtrl.text,
      biblePassage: _passageCtrl.text,
      blocks: _blocks,
    ));
  }

  void _addBlock(String type) {
    setState(() {
      switch (type) {
        case 'heading':
          _blocks.add(ContentBlock.heading("New Heading"));
          break;
        case 'text':
          _blocks.add(ContentBlock.text(""));
          break;
        case 'memory_verse':
          _blocks.add(ContentBlock.memoryVerse(""));
          break;
        case 'numbered':
          _blocks.add(ContentBlock.numberedList(["Point 1"]));
          _listControllers[_blocks.length - 1] = [TextEditingController(text: "Point 1")];
          break;
        case 'bullet':
          _blocks.add(ContentBlock.bulletList(["Item 1"]));
          _listControllers[_blocks.length - 1] = [TextEditingController(text: "Item 1")];
          break;
        case 'quote':
          _blocks.add(ContentBlock.quote(""));
          break;
        case 'prayer':
          _blocks.add(ContentBlock.prayer(""));
          break;
      }
      _notifyParent();
    });
  }

  void _updateTextBlock(int index, String newText) {
    setState(() {
      _blocks[index] = _blocks[index].copyWith(text: newText);
      _notifyParent();
    });
  }

  void _updateListBlock(int blockIndex, int itemIndex, String newText) {
    final controllers = _listControllers[blockIndex]!;
    controllers[itemIndex].text = newText;

    final newItems = controllers.map((c) => c.text).toList();
    setState(() {
      _blocks[blockIndex] = _blocks[blockIndex].copyWith(items: newItems);
      _notifyParent();
    });
  }

  void _addListItem(int blockIndex) {
    final controllers = _listControllers[blockIndex]!;
    final newIndex = controllers.length;
    controllers.add(TextEditingController(text: ""));

    final newItems = controllers.map((c) => c.text).toList();
    setState(() {
      _blocks[blockIndex] = _blocks[blockIndex].copyWith(items: newItems);
      _notifyParent();
    });
  }

  void _removeListItem(int blockIndex, int itemIndex) {
    final controllers = _listControllers[blockIndex]!;
    controllers[itemIndex].dispose();
    controllers.removeAt(itemIndex);

    final newItems = controllers.map((c) => c.text).toList();
    setState(() {
      _blocks[blockIndex] = _blocks[blockIndex].copyWith(items: newItems);
      _notifyParent();
    });
  }

  void _deleteBlock(int index) {
    setState(() {
      // Clean up list controllers
      _listControllers.remove(index)?.forEach((c) => c.dispose());
      _blocks.removeAt(index);

      // Re-index remaining controllers
      final newMap = <int, List<TextEditingController>>{};
      int newIndex = 0;
      for (int oldIndex in _listControllers.keys.where((k) => k != index)) {
        newMap[newIndex++] = _listControllers[oldIndex]!;
      }
      _listControllers.clear();
      _listControllers.addAll(newMap);

      _notifyParent();
    });
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _passageCtrl.dispose();
    _listControllers.values.forEach((list) => list.forEach((c) => c.dispose()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic & Passage
        TextField(
          controller: _topicCtrl,
          decoration: const InputDecoration(
            labelText: "Lesson Topic",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passageCtrl,
          decoration: const InputDecoration(
            labelText: "Bible Passage (e.g. John 3:16-18)",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),

        const Text("Lesson Content", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        if (_blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text("Tap + to add content", style: TextStyle(color: Colors.grey))),
          ),

        // Dynamic Blocks
        ..._blocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          block.type.replaceAll("_", " ").toTitleCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBlock(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Text-based blocks
                    if (block.text != null)
                      TextField(
                        controller: TextEditingController(text: block.text)
                          ..addListener(() => _updateTextBlock(index, TextEditingController(text: block.text).text)),
                        onChanged: (val) => _updateTextBlock(index, val),
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: "Enter content here...",
                          border: OutlineInputBorder(),
                        ),
                      ),

                    // List-based blocks
                    if (block.items != null) ...[
                      ...block.items!.asMap().entries.map((item) {
                        final i = item.key;
                        final text = item.value;
                        final controller = _listControllers[index]?[i];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: controller,
                                  decoration: InputDecoration(
                                    labelText: "${block.type == 'numbered_list' ? 'Point' : 'Item'} ${i + 1}",
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (val) => _updateListBlock(index, i, val),
                                ),
                              ),
                              if (block.items!.length > 1)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removeListItem(index, i),
                                ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () => _addListItem(index),
                        icon: const Icon(Icons.add),
                        label: const Text("Add item"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Add Block Buttons
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            _addButton("Heading", 'heading'),
            _addButton("Text", 'text'),
            _addButton("Memory Verse", 'memory_verse'),
            _addButton("Numbered List", 'numbered'),
            _addButton("Bullet List", 'bullet'),
            _addButton("Quote", 'quote'),
            _addButton("Prayer", 'prayer'),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _addButton(String label, String type) {
    return ElevatedButton.icon(
      onPressed: () => _addBlock(type),
      icon: const Icon(Icons.add, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// Helper extension
extension StringX on String {
  String toTitleCase() => replaceAll("_", " ").split(" ").map((word) => word.isNotEmpty ? "${word[0].toUpperCase()}${word.substring(1).toLowerCase()}" : "").join(" ");
}