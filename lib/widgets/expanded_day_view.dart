import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:forge2d/forge2d.dart';
import 'memo_widget.dart';
import '../models/ball_info.dart';
import '../models/stored_memo.dart';
import '../services/ball_storage_service.dart';
import '../services/memo_limit_service.dart';
import '../services/ad_service.dart';

class ExpandedDayView extends StatefulWidget {
  final DateTime selectedDate;
  final Function(List<BallInfo>) onClose;
  final Function(SharedMemo) onMemoAdded;
  final Function(SharedMemo) onMemoDeleted;
  final Function() onBallAdded;

  ExpandedDayView({
    required this.selectedDate,
    required this.onClose,
    required this.onMemoAdded,
    required this.onMemoDeleted,
    required this.onBallAdded,
  });

  @override
  _ExpandedDayViewState createState() => _ExpandedDayViewState();
}

class _ExpandedDayViewState extends State<ExpandedDayView> with SingleTickerProviderStateMixin {
  late World world;
  List<Ball> balls = [];
  late AnimationController _controller;
  
  late double dateBoxWidth;
  late double dateBoxHeight;

  final _ballStorageService = BallStorageService();
  final MemoLimitService _memoLimitService = MemoLimitService();
  final AdService _adService = AdService();
  int _currentMemoLimit = 12;

  bool _needsSave = false;
  int _frameCount = 0;
  static const int SAVE_INTERVAL = 60;
  List<SharedMemo> sharedMemos = [];
  List<BallInfo> _newBallInfos = []; // 새로 추가된 공 정보를 저장할 리스트
  int _remainingAdViews = 3; // 남은 광고 시청 횟수

  final double _ballRadiusRatio = 0.15; // dateBox 너비의 3%로 설정

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
      _loadNewBallInfos(); // 새로운 메서드 호출
      _loadMemoLimit();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  void _addBall(Color color, DateTime createdAt) {
    final random = math.Random();
    final ballRadius = dateBoxWidth * _ballRadiusRatio;
    final ball = Ball(
      createdAt: createdAt,
      world,
      position: Vector2(
        random.nextDouble() * dateBoxWidth,
        ballRadius
      ),
      radius: ballRadius,
      restitution: 0.5,
      color: color,
    );
    setState(() {
      balls.add(ball);
    });
    _needsSave = true;
    
    widget.onBallAdded();
  }

  void _addWalls() {
    _addWall(Vector2(0, dateBoxHeight), Vector2(dateBoxWidth, dateBoxHeight));
    _addWall(Vector2(0, 0), Vector2(0, dateBoxHeight));
    _addWall(Vector2(dateBoxWidth, 0), Vector2(dateBoxWidth, dateBoxHeight));
  }

  void _addWall(Vector2 start, Vector2 end) {
    final wall = world.createBody(BodyDef()..type = BodyType.static);
    final shape = EdgeShape()..set(start, end);
    wall.createFixture(FixtureDef(shape)..friction = 0.3);
  }

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
    final color = _getColorFromEmoji(emoji);
    final ballRadius = dateBoxWidth * _ballRadiusRatio;
    
    final newBallInfo = BallInfo(
      createdAt: createdAt,
      color: color,
      radius: ballRadius,
      x: 0.5,
      y: 0.1,
    );
    
    setState(() {
      _newBallInfos.add(newBallInfo);
    });
    _ballStorageService.saveNewBallInfos(_newBallInfos);
    
    _addBall(color, createdAt);
  }

  Color _getColorFromEmoji(String emoji) {
    switch (emoji) {
      case '😠': return Colors.red;
      case '😩': return Colors.red;
      case '😊': return const Color(0xFFFFD700);
      case '😎': return const Color(0xFFFFD700);
      case '😢': return Colors.blue;
      case '😴': return Colors.green;
      case '😐': return Colors.green;
      case '🥰': return const Color.fromARGB(255, 255, 134, 231);
      case '🤔': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Future<void> _loadMemos() async {
    final loadedMemos = await _ballStorageService.loadMemos(widget.selectedDate);
    setState(() {
      sharedMemos = loadedMemos ?? [];
    });
  }

  Future<void> _saveMemos() async {
    await _ballStorageService.saveMemos(widget.selectedDate, sharedMemos);
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
    
    // 여기에 저장 로직 추가
    _saveBalls();
    _ballStorageService.saveNewBallInfos(_newBallInfos);
  }

  Future<void> _deleteMemoAndBall(int index) async {
    if (index < 0 || index >= sharedMemos.length) {
      print('Invalid index: $index');
      return;
    }
    final deletedMemo = sharedMemos[index];
    await _ballStorageService.deleteMemoAndBallEverywhere(widget.selectedDate, deletedMemo);
    
    setState(() {
      sharedMemos.removeAt(index);
      balls.removeWhere((ball) => _isSameDateTime(ball.createdAt, deletedMemo.createdAt));
    });
    
    widget.onMemoDeleted(deletedMemo);
    await _loadBalls();
    await _loadNewBallInfos();
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
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return widget.selectedDate.isAtSameMomentAs(tomorrow) || widget.selectedDate.isAfter(tomorrow);
  }

  Future<void> _loadMemoLimit() async {
    _currentMemoLimit = await _memoLimitService.getMemoLimit(widget.selectedDate);
    setState(() {});
  }

  Future<void> _showAdDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('기억 한도 늘리기'),
          content: Text('광고를 보고 기억 한도를 늘리시겠습니까? (남은 횟수: $_remainingAdViews)'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('광고 보기'),
              onPressed: () {
                Navigator.of(context).pop();
                _increaseMemoLimit();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _increaseMemoLimit() async {
    if (_currentMemoLimit < 15 && _remainingAdViews > 0) {
      bool adWatched = await _adService.showAd();
      if (adWatched) {
        _currentMemoLimit = await _memoLimitService.increaseMemoLimit(widget.selectedDate);
        setState(() {
          _remainingAdViews--;
        });
      }
    }
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
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: _currentMemoLimit < 15 && _remainingAdViews > 0
                ? IconButton(
                    icon: Icon(Icons.add, color: Colors.black),
                    onPressed: _showAdDialog,
                  )
                : null,
              title: Text('기억을 추가해보세요', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  if (sharedMemos.length < _currentMemoLimit) {
                                    _addMemo(emoji, text);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('오늘의 메모 한도에 도달했습니다.')),
                                    );
                                  }
                                },
                                memoLimit: _currentMemoLimit,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.all(16),
                          child: sharedMemos.isEmpty
                            ? Center(child: Text('아직 기억이 없습니다. 새로운 기억을 추가해보세요!'))
                            : ListView.builder(
                                itemCount: sharedMemos.length,
                                itemBuilder: (context, index) {
                                  final memo = sharedMemos[index];
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
                                      _deleteMemoAndBall(index);
                                    },
                                    child: ListTile(
                                      leading: Text(memo.emoji, style: TextStyle(fontSize: 24)),
                                      title: Text(memo.text),
                                      subtitle: Text(
                                        '${memo.createdAt.hour}:${memo.createdAt.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
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
    await _ballStorageService.saveNewBallInfos(_newBallInfos);
    widget.onClose(ballInfoList);
    Navigator.of(context).pop();
  }

  Future<void> _loadNewBallInfos() async {
    _newBallInfos = await _ballStorageService.loadNewBallInfos();
    setState(() {});
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