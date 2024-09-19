import 'package:flutter/material.dart';
import '../services/ball_storage_service.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({Key? key}) : super(key: key);

  final BallStorageService _ballStorageService = BallStorageService();

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
}