import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:forge2d/forge2d.dart';
import 'memo_widget.dart';
import '../models/friend.dart';
import '../models/ball_info.dart';
import '../models/stored_memo.dart';
import '../services/ball_storage_service.dart';

class ExpandedDayView extends StatefulWidget {
  final DateTime selectedDate;
  final Function(List<BallInfo>) onClose;
  final VoidCallback onBallsChanged;
  final Function(SharedMemo) onMemoAdded;
  final Function(SharedMemo) onMemoDeleted;

  ExpandedDayView({
    required this.selectedDate,
    required this.onClose,
    required this.onBallsChanged,
    required this.onMemoAdded,
    required this.onMemoDeleted,
  });

  @override
  _ExpandedDayViewState createState() => _ExpandedDayViewState();
}

class _ExpandedDayViewState extends State<ExpandedDayView> with SingleTickerProviderStateMixin {
  List<Friend> friends = [];
  late World world;
  List<Ball> balls = [];
  late AnimationController _controller;
  
  // 날짜 표시 박스의 크기
  late double dateBoxWidth;
  late double dateBoxHeight;

  final _ballStorageService = BallStorageService();

  bool _needsSave = false;
  int _frameCount = 0;
  static const int SAVE_INTERVAL = 60; // 60프레임마다 저장 (약 1초)
  List<SharedMemo> sharedMemos = [];

  @override
  void initState() {
    super.initState();
    world = World(Vector2(0, 160));
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _controller.addListener(_updatePhysics);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalls();
      _addWalls();
      _loadMemos();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 물리 시뮬레이션 업데트
  void _updatePhysics() {
    world.stepDt(1 / 60);
    setState(() {});
    
    _frameCount++;
    if (_frameCount >= SAVE_INTERVAL && _needsSave) {
      _saveBalls();
      _frameCount = 0;
      _needsSave = false;
    }
  }


  // 공 추가
  void _addBall(Color color, double size, DateTime createdAt) {
    print('공 생성: createdAt = $createdAt'); // 디버그 출력 추가
    final random = math.Random();
    final ball = Ball(
      createdAt: createdAt,
      world,
      position: Vector2(
        random.nextDouble() * dateBoxWidth,
        size // 공이 시작하는 높이를 공의 크기로 설정
      ),
      radius: size,
      restitution: 0.8,
      color: color,
    );
    setState(() {
      balls.add(ball);
    });
    _needsSave = true;
    widget.onBallsChanged(); // 콜백 호출
  }

  // 벽 추가 (공 움직임을 제한하기 위함)
  void _addWalls() {
    // 바닥
    _addWall(Vector2(0, dateBoxHeight), Vector2(dateBoxWidth, dateBoxHeight));
    // 왼쪽 벽
    _addWall(Vector2(0, 0), Vector2(0, dateBoxHeight));
    // 오른쪽 벽
    _addWall(Vector2(dateBoxWidth, 0), Vector2(dateBoxWidth, dateBoxHeight));
  }

  // 개별 벽 추가
  void _addWall(Vector2 start, Vector2 end) {
    final wall = world.createBody(BodyDef()..type = BodyType.static);
    final shape = EdgeShape()..set(start, end);
    wall.createFixture(FixtureDef(shape)..friction = 0.3);
  }

  // 공 정보 저장
  Future<void> _saveBalls() async {
    final ballInfoList = balls.map((ball) => BallInfo(
      createdAt: ball.createdAt,
      color: ball.color,
      radius: ball.radius,
      x: ball.body.position.x / dateBoxWidth,
      y: ball.body.position.y / dateBoxHeight,
    )).toList();
    await _ballStorageService.saveBalls(widget.selectedDate, ballInfoList);
  }

  // 공 정보 불러오기
  Future<void> _loadBalls() async {
    final ballInfoList = await _ballStorageService.loadBalls(widget.selectedDate);
    if (ballInfoList.isNotEmpty) {
      setState(() {
        balls = ballInfoList.map((info) => Ball(
          createdAt: info.createdAt,
          world,
          position: Vector2(info.x * dateBoxWidth, info.y * dateBoxHeight),
          radius: info.radius,
          restitution: 0.8,
          color: info.color,
        )).toList();
      });
    }
  }

  void _addBallFromEmoji(String emoji, String text, DateTime createdAt) {
    print('이모지로부터 공 생성: createdAt = $createdAt'); // 디버그 출력 추가
    final color = _getColorFromEmoji(emoji);
    final size = 20.0;
    _addBall(color, size, createdAt);
  }

  Color _getColorFromEmoji(String emoji) {
    switch (emoji) {
      case '😊': return Colors.orange[300]!; // 밝은 주황색
      case '😃': return Colors.yellow[400]!; // 선명한 노란색
      case '😍': return Colors.pink[300]!; // 밝은 분홍색
      case '🥳': return Colors.purple[300]!; // 밝은 보라색
      case '😎': return Colors.blue[400]!; // 선명한 파란색
      case '🤔': return Colors.teal[300]!; // 밝은 청록색
      case '😢': return Colors.lightBlue[300]!; // 밝은 하늘색
      case '😡': return Colors.red[400]!; // 선명한 빨간색
      case '😴': return Colors.indigo[300]!; // 밝은 남색
      case '😌': return Colors.green[400]!; // 선명한 초록색
      case '🥰': return Colors.deepOrange[300]!; // 밝은 진한 주황색
      case '😂': return Colors.cyan[400]!; // 선명한 청록색
      default: return Colors.grey[400]!; // 기본값: 중간 회색
    }
  }

  Future<void> _loadMemos() async {
    final loadedMemos = await _ballStorageService.loadMemos(widget.selectedDate);
    setState(() {
      sharedMemos = loadedMemos;
    });
  }

  Future<void> _saveMemos() async {
    await _ballStorageService.saveMemos(widget.selectedDate, sharedMemos);
    print('Saved ${sharedMemos.length} memos for ${widget.selectedDate}');  // 디버깅용 출력
  }

  void _addMemo(String emoji, String text) {
    final createdAt = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      DateTime.now().hour,
      DateTime.now().minute,
      DateTime.now().second,
    );
    print('메모 생성: createdAt = $createdAt');
    final newMemo = SharedMemo(
      text: text,
      emoji: emoji,
      createdAt: createdAt,
      date: widget.selectedDate,
    );
    setState(() {
      sharedMemos.add(newMemo);
    });
    _saveMemos();
    widget.onMemoAdded(newMemo);
    _addBallFromEmoji(emoji, text, createdAt);
  }

  void _deleteMemoAndBall(int index) {
    final deletedMemo = sharedMemos[index];
    print('메모 삭제: createdAt = ${deletedMemo.createdAt}');
    setState(() {
      sharedMemos.removeAt(index);
      _saveMemos();
      
      balls.removeWhere((ball) {
        final isMatched = _isSameDateTime(ball.createdAt, deletedMemo.createdAt);
        if (isMatched) {
          print('공 삭제: createdAt = ${ball.createdAt}');
        }
        return isMatched;
      });
      _needsSave = true;
      widget.onMemoDeleted(deletedMemo);
    });
    
    _saveBalls();
  }

  bool _isSameDateTime(DateTime a, DateTime b) {
    return a.year == b.year &&
           a.month == b.month &&
           a.day == b.day &&
           a.hour == b.hour &&
           a.minute == b.minute &&
           a.second == b.second;
  }

  bool _isFutureDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.selectedDate.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    dateBoxWidth = screenSize.width * 0.3;
    dateBoxHeight = screenSize.height * 0.3;

    return WillPopScope(
      onWillPop: () async {
        await _saveBallsAndClose();
        return true;
      },
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {
            // 화면의 다른 부분을 터치하면 키보드를 닫습니다.
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text('오늘은 무슨 일이 있었나요?', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: _saveBallsAndClose,
                ),
              ],
            ),
            body: _isFutureDate()
              ? Center(child: Text('미래의 기억은 생성할 수 없어요.'))
              : Container(
                  width: screenSize.width * 0.9,
                  height: screenSize.height * 0.8,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: dateBoxWidth,
                            height: dateBoxHeight,
                            margin: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 16,
                                  top: 16,
                                  child: Text(
                                    '${widget.selectedDate.day}',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                CustomPaint(
                                  painter: BallPainter(balls),
                                  size: Size(dateBoxWidth, dateBoxHeight),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: dateBoxHeight,
                              margin: EdgeInsets.all(16),
                              child: MemoWidget(
                                date: widget.selectedDate,
                                onShare: (String emoji, String text) {
                                  setState(() {
                                    sharedMemos.add(SharedMemo(
                                      emoji: emoji,
                                      text: text,
                                      createdAt: DateTime.now(),
                                      date: widget.selectedDate,
                                    ));
                                    _addBallFromEmoji(emoji, text, DateTime.now());
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(16),
                          child: ListView.builder(
                            itemCount: sharedMemos.length,
                            itemBuilder: (context, index) {
                              final memo = sharedMemos[index];
                              return Column(
                                children: [
                                  ListTile(
                                    leading: Text(memo.emoji, style: TextStyle(fontSize: 24)),
                                    title: Text(memo.text),
                                    trailing: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
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
                                                  onPressed: () {
                                                    _deleteMemoAndBall(index); // 메모와 볼 삭제
                                                    Navigator.of(context).pop(); // 대화 상자 닫기
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  if (index < sharedMemos.length - 1) // 마지막 항목이 아닐 때만 선 추가
                                    Divider(), // 메모 사이에 선 추가
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCircle(Friend friend) {
    return GestureDetector(
      onTapDown: (details) => _addBall(friend.color, 20, DateTime.now()),  // 일반 탭
      onLongPress: () => _addBall(friend.color, 20, DateTime.now()),  // 길게 누르기
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: friend.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 4),
          Text(friend.name, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _saveBallsAndClose() async {
    await _saveBalls();
    await _saveMemos();
    final ballInfoList = balls.map((ball) => BallInfo(
      createdAt: ball.createdAt,
      color: ball.color,
      radius: ball.radius,
      x: ball.body.position.x / dateBoxWidth,
      y: ball.body.position.y / dateBoxHeight,
    )).toList();
    widget.onClose(ballInfoList);
    widget.onBallsChanged(); // 공 정보가 변경되었음을 알림
    Navigator.of(context).pop();
  }
}

class Ball {
  final Body body;
  final Color color;
  final double radius;
  final DateTime createdAt;

  Ball(World world, {required Vector2 position, required this.radius, required double restitution, required this.color, required this.createdAt}) :
    body = world.createBody(BodyDef()
      ..type = BodyType.dynamic
      ..position = position
    ) {
    final shape = CircleShape()..radius = radius;
    body.createFixture(FixtureDef(shape)
      ..shape = shape
      ..restitution = restitution
      ..density = 1.0
      ..friction = 0.2
    );
  }
}

class BallPainter extends CustomPainter {
  final List<Ball> balls;

  BallPainter(this.balls);

  @override
  void paint(Canvas canvas, Size size) { 
    for (final ball in balls) {
      final paint = Paint()..color = ball.color;
      canvas.drawCircle(
        Offset(ball.body.position.x, ball.body.position.y),
        ball.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}