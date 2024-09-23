import 'package:flutter/material.dart';
import '../services/ball_storage_service.dart';
import '../models/stored_memo.dart';
import '../models/ball_info.dart';

class MemoryStorageScreen extends StatefulWidget {
  final Function onMemoryUpdated;

  const MemoryStorageScreen({Key? key, required this.onMemoryUpdated}) : super(key: key);

  @override
  MemoryStorageScreenState createState() => MemoryStorageScreenState();
}

class MemoryStorageScreenState extends State<MemoryStorageScreen> {
  final BallStorageService _ballStorageService = BallStorageService();
  Map<DateTime, List<SharedMemo>> memos = {};
  Map<DateTime, List<BallInfo>> balls = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMemosAndBalls();
  }

  void refreshData() {
    _loadAllMemosAndBalls();
  }

  Future<void> _loadAllMemosAndBalls() async {
    setState(() {
      isLoading = true;
    });
    final allMemos = await _ballStorageService.loadAllMemos();
    final allBalls = await _ballStorageService.loadAllBalls();
    setState(() {
      memos = Map.fromEntries(allMemos.entries.where((entry) => entry.value.isNotEmpty));
      balls = allBalls;
      isLoading = false;
    });
  }

  Future<void> _deleteMemoAndBall(DateTime date, SharedMemo memo) async {
    await _ballStorageService.deleteMemoAndBallEverywhere(date, memo);
    await _loadAllMemosAndBalls();
    widget.onMemoryUpdated();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshData();
    });

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (memos.isEmpty) {
      return Center(child: Text('저장된 기억이 없습니다.'));
    }

    final sortedDates = memos.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayMemos = memos[date]!;
        final dayBalls = balls[date] ?? [];
        return ExpansionTile(
          title: Text('${date.year}년 ${date.month}월 ${date.day}일', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          children: dayMemos.asMap().entries.map((entry) {
            final memo = entry.value;
            final matchingBall = dayBalls.firstWhere(
              (ball) => _isSameDateTime(ball.createdAt, memo.createdAt),
              orElse: () => BallInfo(createdAt: memo.createdAt, color: Colors.grey, radius: 10, x: 0, y: 0),
            );
            return Dismissible(
              key: Key(memo.createdAt.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      title: Text('삭제'),
                      content: Text('이 기억을 삭제 하시겠습니까? \n당신의 머리속에서 사라지진 않습니다.'),
                      actions: <Widget>[
                        TextButton(
                          child: Text('취소'),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                        TextButton(
                          child: Text('삭제'),
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              onDismissed: (direction) {
                _deleteMemoAndBall(date, memo);
              },
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                leading: CircleAvatar(
                  backgroundColor: matchingBall.color,
                  child: Text(memo.emoji, style: TextStyle(fontSize: 24)),
                ),
                title: Text(memo.text, style: TextStyle(fontSize: 12)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  bool _isSameDateTime(DateTime a, DateTime b) {
    return a.year == b.year &&
           a.month == b.month &&
           a.day == b.day &&
           a.hour == b.hour &&
           a.minute == b.minute &&
           a.second == b.second;
  }

  void resetState() {
    memos.clear();
    balls.clear();
    _loadAllMemosAndBalls();
  }
}