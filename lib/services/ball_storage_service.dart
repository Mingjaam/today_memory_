import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ball_info.dart';
import '../models/stored_memo.dart';
import 'package:flutter/material.dart';
import 'package:flame/extensions.dart';

class BallStorageService {
  String _getKey(DateTime date) {
    return 'balls_${date.year}_${date.month}_${date.day}';
  }

  Future<void> saveBalls(DateTime date, List<BallInfo> balls) async {
    final prefs = await SharedPreferences.getInstance();
    final ballInfoList = balls.map((ball) => ball.toJson()).toList();
    await prefs.setString(_getKey(date), jsonEncode(ballInfoList));
  }

  Future<List<BallInfo>> loadBalls(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final ballsJson = prefs.getString(_getKey(date));
    if (ballsJson != null) {
      final ballInfoList = (jsonDecode(ballsJson) as List).map((item) => BallInfo.fromJson(item)).toList();
      return ballInfoList;
    }
    return [];
  }

  Future<Map<DateTime, List<BallInfo>>> loadBallsForDateRange(DateTime start, DateTime end) async {
    final Map<DateTime, List<BallInfo>> ballsMap = {};
    for (DateTime date = start; date.isBefore(end.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      final balls = await loadBalls(date);
      if (balls.isNotEmpty) {
        ballsMap[DateTime(date.year, date.month, date.day)] = balls;
      }
    }
    return ballsMap;
  }

  Future<void> clearAllData() async {
    // 모든 데이터를 지우는 로직 구현
    // 예: SharedPreferences를 사용하는 경우
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  String _getEmojiKey(DateTime date) {
    return 'emojis_${date.year}_${date.month}_${date.day}';
  }

  String _getMemoKey(DateTime date) {
    return 'memos_${date.year}_${date.month}_${date.day}';
  }

  Future<void> saveMemos(DateTime date, List<SharedMemo> memos) async {
    final prefs = await SharedPreferences.getInstance();
    final memoList = memos.map((memo) => memo.toJson()).toList();
    await prefs.setString(_getMemoKey(date), jsonEncode(memoList));
  }

  Future<List<SharedMemo>> loadMemos(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final memosJson = prefs.getString(_getMemoKey(date));
    if (memosJson != null) {
      final memoList = (jsonDecode(memosJson) as List).map((item) => SharedMemo.fromJson(item)).toList();
      return memoList;
    }
    return [];
  }

  Future<Map<DateTime, List<SharedMemo>>> loadAllMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<DateTime, List<SharedMemo>> allMemos = {};
    
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('memos_')) {
        final dateParts = key.substring(6).split('_');
        if (dateParts.length == 3) {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);
          final date = DateTime(year, month, day);
          final memoList = await loadMemos(date);
          allMemos[date] = memoList;
        }
      }
    }
    
    return allMemos;
  }

  Future<void> deleteMemo(DateTime date, SharedMemo memo) async {
    final memos = await loadMemos(date);
    memos.removeWhere((m) => m.text == memo.text && m.emoji == memo.emoji && m.date == memo.date);
    await saveMemos(date, memos);
  }

  Future<Map<DateTime, List<BallInfo>>> loadAllBalls() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<DateTime, List<BallInfo>> allBalls = {};
    
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('balls_')) {
        final dateParts = key.substring(6).split('_');
        if (dateParts.length == 3) {
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);
          final date = DateTime(year, month, day);
          final ballList = await loadBalls(date);
          if (ballList.isNotEmpty) {
            allBalls[date] = ballList;
          }
        }
      }
    }
    
    return allBalls;
  }
  

  Future<void> deleteMemoAndBall(DateTime date, SharedMemo memo) async {
    // 메모 삭제
    final memos = await loadMemos(date);
    memos.removeWhere((m) => _isSameDateTime(m.createdAt, memo.createdAt));
    await saveMemos(date, memos);

    // 공 삭제
    final balls = await loadBalls(date);
    balls.removeWhere((ball) => _isSameDateTime(ball.createdAt, memo.createdAt));
    await saveBalls(date, balls);
  }

  Color _getColorFromEmoji(String emoji) {
    switch (emoji) {
      case '😊': return Colors.orange[300]!;
      case '😃': return Colors.yellow[400]!;
      case '😍': return Colors.red[300]!;
      case '🥰': return Colors.pink[300]!;
      case '😎': return Colors.blue[400]!;
      case '🤔': return Colors.green[400]!;
      case '😢': return Colors.blue[200]!;
      case '😡': return Colors.red[400]!;
      case '😴': return Colors.purple[200]!;
      case '🤮': return Colors.green[200]!;
      case '🥳': return Colors.deepPurple[300]!;
      case '😱': return Colors.amber[300]!;
      case '🤯': return Colors.deepOrange[400]!;
      default: return Colors.grey[400]!;
    }
  }

  bool _isSameDateTime(DateTime a, DateTime b) {
    return a.year == b.year &&
           a.month == b.month &&
           a.day == b.day &&
           a.hour == b.hour &&
           a.minute == b.minute &&
           a.second == b.second;
  }

  String _getBallPositionsKey() {
    return 'ball_positions';
  }

  Future<Map<String, Vector2>> loadBallPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final positionsJson = prefs.getString(_getBallPositionsKey());
    if (positionsJson != null) {
      final Map<String, dynamic> decodedPositions = jsonDecode(positionsJson);
      return decodedPositions.map((key, value) {
        final List<dynamic> position = value;
        return MapEntry(key, Vector2(position[0], position[1]));
      });
    }
    return {};
  }

  Future<void> saveBallPositions(Map<String, Vector2> positions) async {
    final prefs = await SharedPreferences.getInstance();
    final positionsJson = jsonEncode(positions.map((key, value) => 
      MapEntry(key, [value.x, value.y])
    ));
    await prefs.setString(_getBallPositionsKey(), positionsJson);
  }
}
