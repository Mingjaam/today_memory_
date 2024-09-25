import 'package:flutter/material.dart';
import '../services/ball_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  final Function onReset;
  final BallStorageService _ballStorageService = BallStorageService();

  SettingsScreen({Key? key, required this.onReset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text('설정', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          title: Text('전체 초기화'),
          trailing: Icon(Icons.warning, color: Colors.red),
          onTap: () => _showResetConfirmationDialog(context),
        ),
      ],
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
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
                await _resetAllData();
                onReset(); // 모든 탭 초기화
                Navigator.of(context).pop();
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

  Future<void> _resetAllData() async {
    // SharedPreferences의 모든 데이터 삭제
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // BallStorageService를 통한 모든 데이터 삭제
    await _ballStorageService.clearAllData();

    // 새로운 공 정보 삭제
    await _ballStorageService.clearNewBallInfos();

    // 기억 저장소 데이터 삭제
    await _ballStorageService.clearAllMemos();

    // 모든 공 데이터 삭제
    await _ballStorageService.clearAllBalls();

    // 여기에 추가적인 데이터 초기화 로직을 넣을 수 있습니다.
  }
}