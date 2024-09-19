import 'package:flutter/material.dart';
import 'package:forge2d/forge2d.dart';
import '../services/ball_storage_service.dart';
import '../models/ball_info.dart';
import 'dart:math' as math;

class AllBallsScreen extends StatefulWidget {
  const AllBallsScreen({Key? key}) : super(key: key);

  @override
  AllBallsScreenState createState() => AllBallsScreenState();
}

class AllBallsScreenState extends State<AllBallsScreen> with SingleTickerProviderStateMixin {
  final BallStorageService _ballStorageService = BallStorageService();
  Map<DateTime, List<BallInfo>> _allBalls = {};
  bool _isLoading = true;
  int _totalBallCount = 0;
  late World _world;
  late List<Ball> _balls;
  late AnimationController _animationController;
  List<Vector2> _savedPositions = [];

  // 공 크기 조절을 위한 상수 (1.0보다 작은 값으로 설정하여 크기 줄임)
  static const double BALL_SIZE_MULTIPLIER = 0.5; // 예: 원래 크기의 50%로 줄임
  // 중력 조절을 위한 상수
  static const double GRAVITY_STRENGTH = 20.0;

  @override
  void initState() {
    super.initState();
    _loadAllBalls();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    // 저장된 위치 로드
    _loadSavedPositions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBalls() async {
    try {
      final allBalls = await _ballStorageService.loadAllBalls();
      int totalCount = 0;
      allBalls.values.forEach((ballList) {
        totalCount += ballList.length;
      });
      setState(() {
        _allBalls = allBalls;
        _totalBallCount = totalCount;
        _isLoading = false;
      });
      _initializePhysics();
    } catch (e) {
      print('공 로딩 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializePhysics() {
    final gravity = Vector2(0, GRAVITY_STRENGTH);
    _world = World(gravity);
    _balls = [];
    _addWalls();
    _addBalls();
  }

  void _addWalls() {
    final screenSize = MediaQuery.of(context).size;
    final appBarHeight = AppBar().preferredSize.height;
    final bottomNavBarHeight = kBottomNavigationBarHeight;
    final topLeft = Vector2(0, 0);
    final bottomRight = Vector2(screenSize.width, screenSize.height - appBarHeight - bottomNavBarHeight);

    final walls = [
      Wall(topLeft, Vector2(bottomRight.x, topLeft.y)),  // 상단 벽
      Wall(topLeft, Vector2(topLeft.x, bottomRight.y)),  // 좌측 벽
      Wall(Vector2(bottomRight.x, topLeft.y), bottomRight),  // 우측 벽
      Wall(Vector2(topLeft.x, bottomRight.y), bottomRight),  // 하단 벽
    ];

    for (final wall in walls) {
      final bodyDef = BodyDef()
        ..type = BodyType.static
        ..position.setFrom(Vector2.zero());
      final body = _world.createBody(bodyDef);
      final shape = EdgeShape()..set(wall.start, wall.end);
      body.createFixture(FixtureDef(shape)..friction = 0.7);
    }
  }

  void _addBalls() {
    final screenSize = MediaQuery.of(context).size;
    final random = math.Random();

    // 생성 영역 정의
    final areaWidth = screenSize.width * 0.5;  // 화면 너비의 50%
    final areaHeight = screenSize.height * 0.2;  // 화면 높이의 20%
    final areaLeft = (screenSize.width - areaWidth) / 2;  // 중앙 정렬
    final areaTop = screenSize.height * 0.1;  // 상단에서 10% 위치

    _allBalls.values.forEach((ballList) {
      for (int i = 0; i < ballList.length; i++) {
        final ballInfo = ballList[i];
        final adjustedRadius = ballInfo.radius * BALL_SIZE_MULTIPLIER;
        
        Vector2 position;
        if (i < _savedPositions.length) {
          position = _savedPositions[i];
        } else {
          // 정의된 영역 내에서 랜덤 위치 생성
          final x = areaLeft + random.nextDouble() * areaWidth;
          final y = areaTop + random.nextDouble() * areaHeight;
          position = Vector2(x, y);
        }
        
        final ball = Ball(_world, position, adjustedRadius, ballInfo.color);
        _balls.add(ball);
      }
    });
  }

  void _saveBallPositions() {
    _savedPositions = _balls.map((ball) => ball.body.position.clone()).toList();
    // 여기서 _savedPositions를 로컬 저장소나 상태 관리 솔루션에 저장할 수 있습니다.
  }

  void _loadSavedPositions() {
    // 로컬 저장소에서 저장된 위치 불러오기
    // 예시: _savedPositions = 로컬저장소에서_불러온_위치;
    if (_savedPositions.isNotEmpty && _balls.isNotEmpty) {
      for (int i = 0; i < _balls.length; i++) {
        if (i < _savedPositions.length) {
          _balls[i].body.setTransform(_savedPositions[i], 0);
        }
      }
    }
  }

  void saveBallPositions() {
    _saveBallPositions();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return WillPopScope(
      onWillPop: () async {
        _saveBallPositions();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('모든 공'),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '총 $_totalBallCount개',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: AnimatedBuilder(
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
    );
  }
}

class Wall {
  final Vector2 start;
  final Vector2 end;

  Wall(this.start, this.end);
}

class Ball {
  late final Body body;
  final double radius;
  final Color color;

  Ball(World world, Vector2 position, this.radius, this.color) {
    final bodyDef = BodyDef()
      ..type = BodyType.dynamic
      ..position = position;
    body = world.createBody(bodyDef);
    final shape = CircleShape()..radius = radius;
    body.createFixture(FixtureDef(shape)
      ..density = 1.0
      ..friction = 0.3
      ..restitution = 0.2);
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