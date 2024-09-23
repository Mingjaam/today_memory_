import 'package:flutter/material.dart';
import 'dart:async';
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
  bool _isButtonDisabled = false;

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

  void _shareMemo() {
    if (!_isButtonDisabled && _textController.text.trim().isNotEmpty) {
      widget.onShare(selectedEmoji, _textController.text);
      _textController.clear();
      setState(() {
        _isButtonDisabled = true;
      });
      Timer(Duration(seconds: 1), () {
        setState(() {
          _isButtonDisabled = false;
        });
      });
    }
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
              onPressed: (_isButtonDisabled || _textController.text.trim().isEmpty)
                  ? null  // 텍스트가 비어있거나 버튼이 비활성화되면 null 반환
                  : _shareMemo,
              tooltip: '저장하기',
            ),
          ],
        ),
      ],
    );
  }
}