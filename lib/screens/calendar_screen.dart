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

  void _onMemoryUpdated() {
    setState(() {
      _memoryStorageKey = UniqueKey();
    });
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
            key: _memoryStorageKey,
            onMemoryUpdated: _onMemoryUpdated,
          ),
          AllBallsScreen(key: _allBallsKey),
          SettingsScreen(key: _settingsKey),
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
            label: '기억저장소',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bubble_chart),
            label: '모든 공',
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
          setState(() {
            _selectedIndex = index;
            if (index == 0) {
              _calendarKey = UniqueKey();
            } else if (index == 1) {
              _memoryStorageKey = UniqueKey();
            } else if (index == 2) {
              _allBallsKey = UniqueKey();
            } else if (index == 3) {
              _settingsKey = UniqueKey();
            }
          });
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}