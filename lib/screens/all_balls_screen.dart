import 'package:flutter/material.dart';
import 'package:forge2d/forge2d.dart';
import '../models/ball_info.dart';
import '../services/ball_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../services/ad_service.dart';

class AllBallsScreen extends StatefulWidget {
  AllBallsScreen({Key? key}) : super(key: key);
  @override
  AllBallsScreenState createState() => AllBallsScreenState();
}

class AllBallsScreenState extends State<AllBallsScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  // 물리 상수
  static const double GRAVITY_Y = 150;  // 중력 (Y축)
  static const double BALL_DENSITY = 0.3;  // 공 밀도(무게)
  static const double BALL_FRICTION = 1.5;  // 공 마찰
  static const double BALL_RESTITUTION = 0.3;  // 공 반발력
  static const double ALL_BALLS_SCREEN_BALL_RADIUS = 12.0;  // 이 화면에서 생성되는 공의 반지름
  
  // 벽 상수
  static const double WALL_DENSITY = 1.5;  // 벽 밀도
  static const double WALL_FRICTION = 0.3;  // 벽 마찰
  static const double WALL_RESTITUTION = 0.3;  // 벽 반발
  static const double BOTTOM_WALL_HEIGHT_RATIO = 0.27;  // 하단 벽 높이 비율

  final BallStorageService _ballStorageService = BallStorageService();
  List<BallInfo> _newBallInfos = [];
  List<Ball> _balls = [];
  int _newBallIndex = 0;
  late AnimationController _animationController;
  late World _world;
  bool _isInitialized = false;
  bool _needsSave = false;
  int _ballAddCount = 0;  // 공 추가 횟수를 추적하는 새 변수
  final AdService _adService = AdService();
  bool _isAdRemoved = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWalls();
      _loadBallAddCount();  // 추가
      _loadAdRemovalStatus();
    });
  }

  Future<void> _initializeScreen() async {
    _initializePhysics();
    await loadBalls();
    await _loadNewBallInfos();
    await _loadAllBalls();
    await _loadBallAddCount();  // 추가
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> loadBalls() async {
    print("공 불러오는 중..."); // 디버깅용 로그
    _clearBalls(); // 기존 공들 모두 제거
    await _loadSavedBalls();
    await _loadNewBallInfos();
    // _updateTotalBallCount() 호출 제거
  }

  Future<void> saveBalls() async {
    print("공 저장 중..."); // 디버깅용 로그
    await _saveBalls();
    await _ballStorageService.saveNewBallInfos(_newBallInfos.sublist(_newBallIndex));
  }

  void _initializePhysics() {
    final gravity = Vector2(0, GRAVITY_Y);
    _world = World(gravity);
  }

  Future<void> _loadSavedBalls() async {
    final savedBalls = await _ballStorageService.loadAllBallsPositions();
    setState(() {
      for (var ballInfo in savedBalls) {
        final ball = Ball(_world, Vector2(ballInfo.x, ballInfo.y), ballInfo.radius, ballInfo.color, ballInfo.createdAt);
        _balls.add(ball);
      }
    });
  }

  Future<void> _loadNewBallInfos() async {
    _newBallInfos = await _ballStorageService.loadNewBallInfos();
    _newBallIndex = 0; // 인덱스 초기화
    setState(() {});
  }

  Future<void> _loadAllBalls() async {
    final allBalls = await _ballStorageService.loadAllBalls();
    // _totalBallCount 관련 코드 제거
    setState(() {});
  }

  Future<void> _saveBalls() async {
    final ballInfos = _balls.map((ball) => BallInfo(
      x: ball.body.position.x,
      y: ball.body.position.y,
      radius: ball.radius,
      color: ball.color,
      createdAt: ball.createdAt,
    )).toList();
    await _ballStorageService.saveAllBallsPositions(ballInfos);
  }

  void _clearBalls() {
    for (var ball in _balls) {
      _world.destroyBody(ball.body);
    }
    setState(() {
      _balls.clear();
      // _totalBallCount = 0; 제거
    });
  }

  // _updateTotalBallCount() 메서드 제거

  Future<void> reloadBalls() async {
    await loadBalls();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveBalls();
    _saveBallAddCount();  // 추가
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveBalls();
      _saveBallAddCount();  // 추가
    } else if (state == AppLifecycleState.resumed) {
      loadBalls();
      _loadBallAddCount();  // 추가
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    _addWalls();
    return WillPopScope(
      onWillPop: () async {
        if (_needsSave) {
          await _saveBalls();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('기억 저장 공간')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('내 기억의 수: ${_balls.length}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  _world.stepDt(1 / 60);
                  return CustomPaint(
                    painter: BallPainter(_balls),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _newBallIndex < _newBallInfos.length
          ? FloatingActionButton(
              onPressed: _isAdRemoved || _ballAddCount % 6 != 5 ? addNewBall : showAd,
              child: _isAdRemoved || _ballAddCount % 6 != 5
                ? Text(
                    '${_newBallInfos.length - _newBallIndex}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  )
                : Icon(Icons.ad_units, color: Colors.white),
              backgroundColor: _isAdRemoved || _ballAddCount % 6 != 5
                ? const Color.fromARGB(255, 238, 184, 248)
                : Colors.orange,
            )
          : null,
      ),
    );
  }

  void _addWalls() {
    if (!mounted) return;
    final screenSize = MediaQuery.of(context).size;
    final bottomWallHeight = screenSize.height * BOTTOM_WALL_HEIGHT_RATIO;


    final walls = [
      Wall(Vector2(0, 0), Vector2(screenSize.width, 0)),  // 상단 벽
      Wall(Vector2(0, 0), Vector2(0, screenSize.height)),  // 좌측 벽
      Wall(Vector2(screenSize.width, 0), Vector2(screenSize.width, screenSize.height)),  // 우측 벽
      Wall(Vector2(0, screenSize.height - bottomWallHeight), Vector2(screenSize.width, screenSize.height - bottomWallHeight)),  // 하단 벽
    ];

    for (final wall in walls) {
      final bodyDef = BodyDef()
        ..type = BodyType.static
        ..position.setFrom(Vector2.zero());
      final body = _world.createBody(bodyDef);
      final shape = EdgeShape()..set(wall.start, wall.end);
      body.createFixture(FixtureDef(shape)
      ..density = WALL_DENSITY
      ..friction = WALL_FRICTION
      ..restitution = WALL_RESTITUTION);
    }
  }

  void addNewBall() {
    if (_newBallIndex < _newBallInfos.length) {
      final newBallInfo = _newBallInfos[_newBallIndex];
      final screenSize = MediaQuery.of(context).size;
      
      final position = Vector2(
        screenSize.width * 0.5 + (Random().nextDouble() - 0.5) * 20,
        screenSize.height * 0.1
      );

      final ball = Ball(_world, position, ALL_BALLS_SCREEN_BALL_RADIUS, newBallInfo.color, newBallInfo.createdAt);
      setState(() {
        _balls.add(ball);
        _newBallIndex++;
        _ballAddCount++;  // 공 추가 횟수 증가
      });
      _saveBallAddCount();  // 추가

      if (_newBallIndex == _newBallInfos.length) {
        _ballStorageService.clearNewBallInfos();
      }
    }
  }

  void showAd() async {
    if (_isAdRemoved) {
      addNewBall();
      return;
    }
    
    print("광고를 표시합니다.");
    bool adShown = await _adService.showAd();
    if (adShown) {
      setState(() {
        _ballAddCount = 0;
      });
      _saveBallAddCount();
      addNewBall();
    } else {
      print("광고 표시에 실패했습니다.");
    }
  }

  void resetState() {
    _clearBalls();
    _newBallIndex = 0;
    // _updateTotalBallCount(); 제거
  }

  Future<void> _saveBallAddCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ballAddCount', _ballAddCount);
  }

  Future<void> _loadBallAddCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ballAddCount = prefs.getInt('ballAddCount') ?? 0;
    });
  }

  Future<void> _loadAdRemovalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAdRemoved = prefs.getBool('isAdRemoved') ?? false;
    });
  }

  // 광고 제거 구매 시 호출되는 함수
  Future<void> removeAds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdRemoved', true);
    setState(() {
      _isAdRemoved = true;
    });
  }
}

class Ball {
  final Body body;
  final Color color;
  final double radius;
  final DateTime createdAt;

  Ball(World world, Vector2 position, this.radius, this.color, this.createdAt)
      : body = world.createBody(BodyDef()
          ..type = BodyType.dynamic
          ..position = position) {
    final shape = CircleShape()..radius = radius;
    body.createFixture(FixtureDef(shape)
      ..density = AllBallsScreenState.BALL_DENSITY
      ..friction = AllBallsScreenState.BALL_FRICTION
      ..restitution = AllBallsScreenState.BALL_RESTITUTION);
  }
}

class BallPainter extends CustomPainter {
  final List<Ball> balls;
  final int ballCount;

  BallPainter(this.balls) : ballCount = balls.length;

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

class Wall {
  final Vector2 start;
  final Vector2 end;

  Wall(this.start, this.end);
}
