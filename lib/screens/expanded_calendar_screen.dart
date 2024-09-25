import 'package:flutter/material.dart';
import '../widgets/full_calendar.dart';
import '../widgets/memo_widget.dart';


class ExpandedCalendarScreen extends StatefulWidget {
  final DateTime selectedDate;

  ExpandedCalendarScreen({required this.selectedDate});

  @override
  _ExpandedCalendarScreenState createState() => _ExpandedCalendarScreenState();
}

class _ExpandedCalendarScreenState extends State<ExpandedCalendarScreen> {
  List<Map<String, String>> savedMemos = [];

  void addMemo(String emoji, String text) {
    setState(() {
      savedMemos.add({'emoji': emoji, 'text': text});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.selectedDate.toString().split(' ')[0]}')),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FullCalendar(
                  selectedDate: widget.selectedDate,
                  onDaySelected: (selectedDay) {
                    setState(() {
                      // 선택된 날짜 업데이트
                    });
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: 
                MemoWidget(
                  date: widget.selectedDate,
                  onShare: (String emoji, String text) {
                    addMemo(emoji, text);
                  },
                  memoLimit: 5, // 또는 원하는 숫자로 설정
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: savedMemos.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Text(savedMemos[index]['emoji'] ?? ''),
                  title: Text(savedMemos[index]['text'] ?? ''),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}