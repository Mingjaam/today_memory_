import 'package:flutter/material.dart';
import '../services/ball_storage_service.dart';
import '../models/stored_memo.dart';
import '../models/ball_info.dart';

class MemoryStorageScreen extends StatefulWidget {
  final Function onMemoryUpdated;

  const MemoryStorageScreen({Key? key, required this.onMemoryUpdated}) : super(key: key);

  @override
  _MemoryStorageScreenState createState() => _MemoryStorageScreenState();
}

class _MemoryStorageScreenState extends State<MemoryStorageScreen> {
  final BallStorageService _ballStorageService = BallStorageService();
  Map<DateTime, List<SharedMemo>> memos = {};
  Map<DateTime, List<BallInfo>> balls = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllMemosAndBalls();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAllMemosAndBalls();
  }

  Future<void> _loadAllMemosAndBalls() async {
    setState(() {
      isLoading = true;
    });
    final allMemos = await _ballStorageService.loadAllMemos();
    final allBalls = await _ballStorageService.loadAllBalls();
    setState(() {
      // 메모가 있는 날짜만 필터링
      memos = Map.fromEntries(allMemos.entries.where((entry) => entry.value.isNotEmpty));
      balls = allBalls;
      isLoading = false;
    });
  }

  Future<void> _deleteMemoAndBall(DateTime date, SharedMemo memo) async {
    await _ballStorageService.deleteMemoAndBall(date, memo);
    await _loadAllMemosAndBalls(); // 전체 데이터를 다시 로드
    widget.onMemoryUpdated(); // 메모 삭제 후 캘린더 업데이트
  }

  @override
  Widget build(BuildContext context) {
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
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: CircleAvatar(
                backgroundColor: matchingBall.color,
                child: Text(memo.emoji, style: TextStyle(fontSize: 24)),
              ),
              title: Text(memo.text, style: TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  // 삭제 확인 대화 상자 표시
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('삭제'),
                        content: Text('이 기억을 삭제 하시겠습니까? \n당신의 머리속에서 사라지진 않습니다.'),
                        actions: <Widget>[
                          TextButton(
                            child: Text('취소'),
                            onPressed: () {
                              Navigator.of(context).pop(); // 대화 상자 닫기
                            },
                          ),
                          TextButton(
                            child: Text('삭제'),
                            onPressed: () async {
                              await _deleteMemoAndBall(date, memo); // 메모와 볼 삭제
                              Navigator.of(context).pop(); // 대화 상자 닫기
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
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
}