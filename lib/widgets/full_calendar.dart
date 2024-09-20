import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:forge2d/forge2d.dart';
import 'package:today_memory/models/stored_memo.dart';
import 'dart:math' as math;
import 'expanded_day_view.dart';
import '../models/ball_info.dart';
import '../services/ball_storage_service.dart';
import '../utils/physics_engine.dart';

class FullCalendar extends StatefulWidget {
  final Function(DateTime) onDaySelected;
  final DateTime? selectedDate;  // 이 줄 추가

  const FullCalendar({
    Key? key,
    required this.onDaySelected,
    this.selectedDate,  // 이 줄 추가
  }) : super(key: key);

  @override
  _FullCalendarState createState() => _FullCalendarState();
}

class _FullCalendarState extends State<FullCalendar> with SingleTickerProviderStateMixin {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final BallStorageService _ballStorageService = BallStorageService();
  Map<DateTime, List<BallInfo>> _ballsMap = {};
  Map<DateTime, PhysicsEngine> _physicsEngines = {};
  late AnimationController _animationController;
  final double _ballRadiusRatio = 0.4;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate ?? DateTime.now();
    _selectedDay = widget.selectedDate;
    _loadBallsForMonth(_focusedDay);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 16),
    )..addListener(() {
      setState(() {
        _updatePhysics();
      });
    });
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePhysics() {
    for (var engine in _physicsEngines.values) {
      engine.step(1 / 60);  // 60 FPS로 시뮬레이션
    }
  }

  Future<void> _loadBallsForMonth(DateTime month) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);
    
    final newBallsMap = await _ballStorageService.loadBallsForDateRange(startDate, endDate);
    
    setState(() {
      _ballsMap = newBallsMap;
      _createPhysicsEngines();
    });
  }

  void _createPhysicsEngines() {
    _physicsEngines.clear();
    final cellSize = Vector2(MediaQuery.of(context).size.width / 7, MediaQuery.of(context).size.height / 8);
    
    // 공이 있는 모든 날짜에 대해 PhysicsEngine 생성
    Set<DateTime> datesWithContent = Set<DateTime>.from(_ballsMap.keys);
    
    for (var date in datesWithContent) {
      final balls = _ballsMap[date] ?? [];
      
      final engine = PhysicsEngine(
        gravity: Vector2(0, 30),
        worldWidth: cellSize.x,
        worldHeight: cellSize.y,
      );
      
      for (var ball in balls) {
        engine.addBall(ball, _ballRadiusRatio);
      }
      
      _physicsEngines[date] = engine;
    }
  }

  void _updateCalendar() {
    setState(() {
      _loadBallsForMonth(_focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.08), // 스크린 높이의 2% 여백 추가
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0
          ),
          child: Text(
            "${_focusedDay.year}년, ${_focusedDay.month}월의 기억들..",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        TableCalendar(
          firstDay: DateTime.utc(2010, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay,
          sixWeekMonthsEnforced: true,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay,) {
            DateTime today = DateTime.now();
            DateTime tomorrow = DateTime(today.year, today.month, today.day).add(Duration(days: 1));

            if (selectedDay.isBefore(tomorrow)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showExpandedDayView(selectedDay);
            } else {
              _showFutureWarning();
            }
          },

          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
            _updateCalendar();
            _createPhysicsEngines();
            _updatePhysics();
          },
          
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: EdgeInsets.zero,
            cellPadding: EdgeInsets.zero,
          ),
          daysOfWeekHeight: 20, // 요일 행의 높이를 줄임
          rowHeight: (MediaQuery.of(context).size.height - 
                      AppBar().preferredSize.height - 
                      MediaQuery.of(context).padding.top - 
                      20 - 8) / 7, // 캘린더 셀의 높이를 조정
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: false,
            leftChevronVisible: false,
            rightChevronVisible: false,
            titleTextStyle: TextStyle(fontSize: 0), // 기본 헤더 텍스트 숨기기
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              return _buildCalendarCell(day, false, false);
            },
            selectedBuilder: (context, day, focusedDay) {
              return _buildCalendarCell(day, true, false);
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildCalendarCell(day, false, true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCell(DateTime day, bool isSelected, bool isToday) {
    final balls = _ballsMap[DateTime(day.year, day.month, day.day)] ?? [];
    final engine = _physicsEngines[DateTime(day.year, day.month, day.day)];
    
    // 요일에 따른 색상 설정
    Color dayColor;
    if (day.weekday == DateTime.sunday) {
      dayColor = Colors.red;
    } else if (day.weekday == DateTime.saturday) {
      dayColor = Colors.blue;
    } else {
      dayColor = isSelected ? Colors.blue : (isToday ? Colors.blue : Colors.black);
    }
    
    return Container(
      margin: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.3) : (isToday ? Colors.blue.withOpacity(0.1) : null),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  color: dayColor,
                  fontWeight: isSelected || isToday ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
          if (balls.isNotEmpty)
            CustomPaint(
              painter: BallPainter(engine, balls, _ballRadiusRatio),
              size: Size(MediaQuery.of(context).size.width / 7, MediaQuery.of(context).size.height / 8),
            ),
        ],
      ),
    );
  }

  void _showExpandedDayView(DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.all(20),
          child: ExpandedDayView(
            selectedDate: selectedDay,
            onClose: (List<BallInfo> updatedBalls) async {
              await _ballStorageService.saveBalls(selectedDay, updatedBalls);
              _loadBallsForMonth(_focusedDay);
              setState(() {});
            },
            onBallAdded: () {
              _loadBallsForMonth(_focusedDay);
              setState(() {});
            },
            // onBallsChanged 매개변수 제거
            onMemoAdded: (SharedMemo memo) {
              _loadBallsForMonth(_focusedDay);
              setState(() {});
            },
            onMemoDeleted: (SharedMemo memo) {
              _loadBallsForMonth(_focusedDay);
              setState(() {});
            },
          ),
        );
      },
    );
  }

  void _showFutureWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '오늘,기억',
            style: TextStyle(fontSize: 16), 
          ),
          content: Text('미래의 기억은 생성할 수 없어요.'),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(FullCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      _loadBallsForMonth(widget.selectedDate ?? DateTime.now());
    }
  }
}

class BallPainter extends CustomPainter {
  final PhysicsEngine? engine;
  final List<BallInfo> balls;
  final double radiusRatio;

  BallPainter(this.engine, this.balls, this.radiusRatio);

  @override
  void paint(Canvas canvas, Size size) {
    final positions = engine?.getPositions() ?? [];
    
    // 공 그리기
    for (int i = 0; i < positions.length && i < balls.length; i++) {
      final paint = Paint()
        ..color = balls[i].color.withOpacity(1.0)
        ..style = PaintingStyle.fill;
      final radius = math.max(balls[i].radius * radiusRatio, 5.0);
      canvas.drawCircle(
        Offset(positions[i].x, positions[i].y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}