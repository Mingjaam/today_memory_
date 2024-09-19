import 'package:flutter/material.dart';
import '../utils/emiji_picker.dart';

class MemoWidget extends StatefulWidget {
  final DateTime date;
  final Function(String emoji, String text) onShare;

  MemoWidget({required this.date, required this.onShare});

  @override
  _MemoWidgetState createState() => _MemoWidgetState();
}

class _MemoWidgetState extends State<MemoWidget> {
  String selectedEmoji = '😊';
  TextEditingController _textController = TextEditingController();

  void _openEmojiPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EmojiPicker(
          onEmojiSelected: (emoji) {
            setState(() {
              selectedEmoji = emoji;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(hintText: '메모를 입력하세요'),
            maxLines: null,
            expands: true,
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _openEmojiPicker,
              child: Container(
                padding: EdgeInsets.all(8),
                child: Text(selectedEmoji, style: TextStyle(fontSize: 24)),
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _textController.text.trim().isEmpty
                  ? null  // 텍스트가 비어있으면 버튼 비활성화
                  : () {
                      widget.onShare(selectedEmoji, _textController.text);
                      _textController.clear();
                    },
              tooltip: '저장하기',
            ),
          ],
        ),
      ],
    );
  }
}