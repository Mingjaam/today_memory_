import 'package:flutter/material.dart';
import '../widgets/full_calendar.dart';
import 'expanded_calendar_screen.dart';
import '../services/ball_storage_service.dart';
import '../screens/memory_storage_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final BallStorageService _ballStorageService = BallStorageService();
  int _selectedIndex = 0;
  Key _memoryStorageKey = UniqueKey();
  Key _calendarKey = UniqueKey();

  void _resetAllData() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('전체 초기화'),
          content: Text('모든 데이터를 초기화하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: <Widget>[
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('초기화'),
              onPressed: () async {
                await _ballStorageService.clearAllData();
                Navigator.of(context).pop();
                _onMemoryUpdated();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('모든 데이터가 초기화되었습니다.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _onMemoryUpdated() {
    setState(() {
      _memoryStorageKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomNavBarHeight = screenHeight * 0.08;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            FullCalendar(
              key: _calendarKey,
              onDaySelected: (selectedDay) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpandedCalendarScreen(selectedDate: selectedDay),
                  ),
                ).then((_) {
                  setState(() {});
                });
              },
            ),
            MemoryStorageScreen(
              key: _memoryStorageKey,
              onMemoryUpdated: () {
                setState(() {
                  _memoryStorageKey = UniqueKey();
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: bottomNavBarHeight,
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: '캘린더',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storage),
              label: '기억저장소',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          iconSize: 20,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
              if (index == 0) {
                _calendarKey = UniqueKey();
              } else if (index == 1) {
                _memoryStorageKey = UniqueKey();
              }
            });
          },
          selectedLabelStyle: TextStyle(height: 1.5),
          unselectedLabelStyle: TextStyle(height: 1.5),
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}