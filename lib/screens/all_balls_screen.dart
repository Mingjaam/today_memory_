import 'package:flutter/material.dart';
import 'package:forge2d/forge2d.dart';
import '../models/ball_info.dart';
import '../services/ball_storage_service.dart';

class AllBallsScreen extends StatefulWidget {
  AllBallsScreen({Key? key}) : super(key: key);
  @override
  AllBallsScreenState createState() => AllBallsScreenState();
}

class AllBallsScreenState extends State<AllBallsScreen> with SingleTickerProviderStateMixin {
  final BallStorageService _ballStorageService = BallStorageService();
  List<BallInfo> _newBallInfos = [];
  List<Ball> _balls = [];
  int _newBallIndex = 0;
  late AnimationController _animationController;
  late World _world;
  int _totalBallCount = 0;  // 전체 공 수

  @override
  void initState() {
    super.initState();
    _loadNewBallInfos();
    _loadAllBalls();
    _initializePhysics();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  Future<void> _loadAllBalls() async {
    final allBalls = await _ballStorageService.loadAllBalls();
    _totalBallCount = allBalls.values.fold(0, (sum, list) => sum + list.length);
    setState(() {});
  }

  void _initializePhysics() {
    final gravity = Vector2(0, 10);
    _world = World(gravity);
  }

  @override
  Widget build(BuildContext context) {
    _addWalls();
    return Scaffold(
      appBar: AppBar(title: Text('모든 공')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('전체 공: $_totalBallCount'),
                Text('생성된 공: ${_balls.length}'),
                Text('남은 공: ${_newBallInfos.length - _newBallIndex}'),
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
            onPressed: addNewBall,
            child: Icon(Icons.add),
          )
        : null,
    );
  }

  void _addWalls() {
    if (_world.bodies.isEmpty) {  // 벽이 아직 추가되지 않았는지 확인
      final screenSize = MediaQuery.of(context).size;
      final walls = [
        Wall(Vector2(0, 0), Vector2(screenSize.width, 0)),  // 상단 벽
        Wall(Vector2(0, 0), Vector2(0, screenSize.height)),  // 좌측 벽
        Wall(Vector2(screenSize.width, 0), Vector2(screenSize.width, screenSize.height)),  // 우측 벽
        Wall(Vector2(0, screenSize.height), Vector2(screenSize.width, screenSize.height)),  // 하단 벽
      ];

      for (final wall in walls) {
        final bodyDef = BodyDef()
          ..type = BodyType.static
          ..position.setFrom(Vector2.zero());
        final body = _world.createBody(bodyDef);
        final shape = EdgeShape()..set(wall.start, wall.end);
        body.createFixture(FixtureDef(shape)..friction = 0.3);
      }
    }
  }

  Future<void> _loadNewBallInfos() async {
    _newBallInfos = await _ballStorageService.loadNewBallInfos();
    setState(() {});
  }

  void addNewBall() {
    if (_newBallIndex < _newBallInfos.length) {
      final newBallInfo = _newBallInfos[_newBallIndex];
      final screenSize = MediaQuery.of(context).size;
      final position = Vector2(
        newBallInfo.x * screenSize.width,
        newBallInfo.y * screenSize.height
      );

      final ball = Ball(_world, position, newBallInfo.radius, newBallInfo.color);
      setState(() {
        _balls.add(ball);
        _newBallIndex++;
      });

      if (_newBallIndex == _newBallInfos.length) {
        _ballStorageService.clearNewBallInfos();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class Ball {
  late final Body body;
  final Color color;
  final double radius;

  Ball(World world, Vector2 position, this.radius, this.color) {
    final bodyDef = BodyDef()
      ..type = BodyType.dynamic
      ..position = position;
    body = world.createBody(bodyDef);
    final shape = CircleShape()..radius = radius;
    body.createFixture(FixtureDef(shape)
      ..density = 1.0
      ..friction = 0.3
      ..restitution = 0.6);
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

class Wall {
  final Vector2 start;
  final Vector2 end;

  Wall(this.start, this.end);
}
