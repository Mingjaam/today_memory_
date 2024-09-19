import 'package:flutter/material.dart';
import 'package:forge2d/forge2d.dart';

class BallInfo {
  final DateTime createdAt;  // id 대신 생성 시간 사용
  Color color;
  double radius;
  double x;
  double y;

  BallInfo({
    required this.createdAt,
    required this.color,
    required this.radius,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() => {
    'createdAt': createdAt.toIso8601String(),
    'color': color.value,
    'radius': radius,
    'x': x,
    'y': y,
  };

  factory BallInfo.fromJson(Map<String, dynamic> json) => BallInfo(
    createdAt: DateTime.parse(json['createdAt']),
    color: Color(json['color'] as int),
    radius: json['radius'] as double,
    x: json['x'] as double,
    y: json['y'] as double,
  );

  bool isCloseTo(double x, double y, {double tolerance = 0.1}) {
    return (this.x - x).abs() < tolerance && (this.y - y).abs() < tolerance;
  }
}

class BallInfoWithPosition {
  final BallInfo ballInfo;
  Vector2 position;

  BallInfoWithPosition({
    required this.ballInfo,
    required this.position,
  });
}