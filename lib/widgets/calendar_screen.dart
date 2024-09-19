import 'package:flutter/material.dart';
import 'full_calendar.dart';
import '../screens/expanded_calendar_screen.dart';
import '../services/ball_storage_service.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import 'package:today_memory/screens/memory_storage_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final BallStorageService _ballStorageService = BallStorageService();
  int _selectedIndex = 0;

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
                setState(() {}); // 캘린더 새로고침
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            FullCalendar(
              onDaySelected: (selectedDay) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExpandedCalendarScreen(selectedDate: selectedDay),
                  ),
                ).then((_) {
                  setState(() {}); // 화면 갱신
                });
              },
            ),
            MemoryStorageScreen(
              onMemoryUpdated: () => setState(() {}),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('설정', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 20),
                  Consumer<ThemeService>(
                    builder: (context, themeService, child) {
                      return SwitchListTile(
                        title: Text('다크 모드'),
                        value: themeService.isDarkMode,
                        onChanged: (value) {
                          themeService.toggleTheme();
                        },
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _resetAllData,
                    child: Text('전체 초기화'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 90, // 높이를 80으로 증가
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
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12, // 폰트 크기 조정
          unselectedFontSize: 12,
          iconSize: 24, // 아이콘 크기 유지
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          // 아이콘을 중앙 정렬하기 위한 속성 추가
          selectedLabelStyle: TextStyle(height: 1.5),
          unselectedLabelStyle: TextStyle(height: 1.5),
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}