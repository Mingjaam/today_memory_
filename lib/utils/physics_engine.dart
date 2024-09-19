import 'package:forge2d/forge2d.dart';
import '../models/ball_info.dart';
import 'dart:math' as math;

class PhysicsEngine {
  late World world;
  final Vector2 gravity;
  final double worldWidth;
  final double worldHeight;

  PhysicsEngine({
    required this.gravity,
    required this.worldWidth,
    required this.worldHeight,
  }) {
    world = World(gravity);
    _addWalls();
  }

  void _addWalls() {
    final margin = 5.0; // 벽과 셀 경계 사이의 여백
    final topLeft = Vector2(margin, margin);
    final bottomRight = Vector2(worldWidth - margin, worldHeight - margin);

    // 바닥
    _addWall(Vector2(topLeft.x, bottomRight.y), Vector2(bottomRight.x, bottomRight.y));
    // 왼쪽 벽
    _addWall(topLeft, Vector2(topLeft.x, bottomRight.y));
    // 오른쪽 벽
    _addWall(Vector2(bottomRight.x, topLeft.y), bottomRight);
    // 천장
    _addWall(topLeft, Vector2(bottomRight.x, topLeft.y));
  }

  void _addWall(Vector2 start, Vector2 end) {
    final wall = world.createBody(BodyDef()..type = BodyType.static);
    final shape = EdgeShape()..set(start, end);
    wall.createFixture(FixtureDef(shape)..friction = 0.3);
  }

  void addBall(BallInfo ballInfo, double radiusRatio) {
    final bodyDef = BodyDef()
      ..type = BodyType.dynamic
      ..position = Vector2(worldWidth / 2, worldHeight / 2);
    final body = world.createBody(bodyDef);
    final shape = CircleShape()..radius = ballInfo.radius * radiusRatio;
    final fixtureDef = FixtureDef(shape)
      ..density = 1.0
      ..friction = 0.3
      ..restitution = 0.6;
    body.createFixture(fixtureDef);
  
    // 초기 속도 부여
    body.linearVelocity = Vector2(
      (math.Random().nextDouble() - 0.5) * 10,
      (math.Random().nextDouble() - 0.5) * 10
    );
  }

  void step(double dt) {
    world.stepDt(dt);
  }

  List<Vector2> getPositions() {
    return world.bodies
        .where((body) => body.fixtures.isNotEmpty && body.fixtures.first.shape is CircleShape)
        .map((body) => body.position)
        .toList();
  }
}