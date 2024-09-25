import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/emiji_picker.dart';
import '../services/ball_storage_service.dart';

class MemoWidget extends StatefulWidget {
  final DateTime date;
  final Function(String emoji, String text) onShare;
  final int memoLimit;

  MemoWidget({required this.date, required this.onShare, required this.memoLimit});

  @override
  _MemoWidgetState createState() => _MemoWidgetState();
}

class _MemoWidgetState extends State<MemoWidget> {
  String selectedEmoji = '😊';
  TextEditingController _textController = TextEditingController();
  bool _isButtonDisabled = false;
  int _memoCount = 0;
  final BallStorageService _ballStorageService = BallStorageService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMemoCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoCount() async {
    final memos = await _ballStorageService.loadMemos(widget.date);
    if (mounted) {
      setState(() {
        _memoCount = memos.length;
      });
    }
  }

  void _openEmojiPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EmojiPicker(
          onEmojiSelected: (emoji) {
            if (mounted) {
              setState(() {
                selectedEmoji = emoji;
              });
            }
          },
        );
      },
    );
  }

  void _shareMemo() {
    if (!_isButtonDisabled && _textController.text.trim().isNotEmpty) {
      widget.onShare(selectedEmoji, _textController.text);
      _textController.clear();
      if (mounted) {
        setState(() {
          _isButtonDisabled = true;
          _memoCount++;
        });
      }
      _timer?.cancel();
      _timer = Timer(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isButtonDisabled = false;
          });
        }
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
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: (_isButtonDisabled || _textController.text.trim().isEmpty || _memoCount >= widget.memoLimit)
                      ? null
                      : _shareMemo,
                  tooltip: '저장하기',
                ),
                Text(
                  '$_memoCount/${widget.memoLimit}',
                  style: TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}