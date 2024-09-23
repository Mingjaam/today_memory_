import 'package:flutter/material.dart';
import '../widgets/full_calendar.dart';
import 'expanded_calendar_screen.dart';
import '../screens/memory_storage_screen.dart';
import '../screens/all_balls_screen.dart';
import '../screens/settings_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedIndex = 0;
  Key _calendarKey = UniqueKey();
  Key _memoryStorageKey = UniqueKey();
  Key _allBallsKey = UniqueKey();
  Key _settingsKey = UniqueKey();
  final GlobalKey<AllBallsScreenState> _allBallsScreenKey = GlobalKey<AllBallsScreenState>();
  final GlobalKey<MemoryStorageScreenState> _memoryStorageScreenKey = GlobalKey<MemoryStorageScreenState>();

  void _onMemoryUpdated() {
    setState(() {
      _memoryStorageKey = UniqueKey();
    });
    _allBallsScreenKey.currentState?.reloadBalls();
  }

  void resetAllTabs() {
    setState(() {
      _calendarKey = UniqueKey();
      _memoryStorageKey = UniqueKey();
      _allBallsKey = UniqueKey();
      _settingsKey = UniqueKey();
    });
    (_allBallsScreenKey.currentState as AllBallsScreenState).resetState();
    (_memoryStorageScreenKey.currentState as MemoryStorageScreenState).resetState();
    // 여기에 다른 탭의 초기화 로직을 추가할 수 있습니다.
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      
      if (index == 0) { // '모든 공' 탭
        (_allBallsScreenKey.currentState as AllBallsScreenState).loadBalls();
      } else if (index == 1) { // '기억 저장소' 탭
        (_memoryStorageScreenKey.currentState as MemoryStorageScreenState).resetState();
      }
      // 다른 탭에 대한 로직...
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
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
                setState(() {
                  _calendarKey = UniqueKey();
                });
              });
            },
          ),
          MemoryStorageScreen(
            key: _memoryStorageScreenKey,
            onMemoryUpdated: _onMemoryUpdated,
          ),
          AllBallsScreen(key: _allBallsScreenKey),
          SettingsScreen(
            key: _settingsKey,
            onReset: resetAllTabs,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: '기억 리스트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bubble_chart),
            label: '기억저장소',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (_selectedIndex != index) {
            if (_selectedIndex == 2) {
              // 모든 공 탭에서 다른 탭으로 이동할 때 저장
              print("모든 공 탭에서 나가기 전 공 저장 중"); // 디버깅을 위한 로그
              _allBallsScreenKey.currentState?.saveBalls();
            }
            setState(() {
              _selectedIndex = index;
              if (index == 2) {
                // 모든 공 탭으로 이동할 때 불러오기
                print("모든 공 탭으로 들어갈 때 공 불러오는 중"); // 디버깅을 위한 로그
                _allBallsScreenKey.currentState?.loadBalls();
              }
            });
          }
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}