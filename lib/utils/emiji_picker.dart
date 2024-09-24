import 'package:flutter/material.dart';

class EmojiPicker extends StatelessWidget {
  final Function(String) onEmojiSelected;

  EmojiPicker({required this.onEmojiSelected});

  final List<String> emojis = ['🥰', '😊', '😎', '🤔', '😐', '😴', '😢', '😩', '😠'];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        width: 300, // 너비 고정
        height: 340, // 높이 고정
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('지금 기분은 어떤가요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      onEmojiSelected(emojis[index]);
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          emojis[index],
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}