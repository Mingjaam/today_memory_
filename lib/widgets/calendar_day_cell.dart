import 'package:flutter/material.dart';
import '../models/ball_info.dart';
import 'dart:math' as math;

class CalendarDayCell extends StatelessWidget {
  final DateTime date;
  final List<BallInfo> balls;
  final bool isSelected;
  final bool isToday;  // 이 줄을 추가

  const CalendarDayCell({
    Key? key,
    required this.date,
    required this.balls,
    required this.isSelected,
    required this.isToday,  // 이 줄을 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(
                '${date.day}',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          CustomPaint(
            painter: BallPainter(balls),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }
}

class BallPainter extends CustomPainter {
  final List<BallInfo> balls;

  BallPainter(this.balls);

  @override
  void paint(Canvas canvas, Size size) {
    for (final ball in balls) {
      final paint = Paint()..color = ball.color;
      final relativeX = ball.x * size.width;
      final relativeY = ball.y * size.height;
      final relativeRadius = ball.radius * math.min(size.width, size.height);
      
      canvas.drawCircle(
        Offset(relativeX, relativeY),
        relativeRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}