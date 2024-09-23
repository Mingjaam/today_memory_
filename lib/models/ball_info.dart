import 'package:flutter/material.dart';

class BallInfo {
  final DateTime createdAt;
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
    'x': x,
    'y': y,
    'radius': radius,
    'color': color.value,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BallInfo.fromJson(Map<String, dynamic> json) => BallInfo(
    x: json['x'],
    y: json['y'],
    radius: json['radius'],
    color: Color(json['color']),
    createdAt: DateTime.parse(json['createdAt']),
  );

  bool isCloseTo(double x, double y, {double tolerance = 0.1}) {
    return (this.x - x).abs() < tolerance && (this.y - y).abs() < tolerance;
  }

  BallInfo copyWith() {
    return BallInfo(
      createdAt: createdAt,
      color: color,
      radius: radius,
      x: x,
      y: y,
    );
  }
}
