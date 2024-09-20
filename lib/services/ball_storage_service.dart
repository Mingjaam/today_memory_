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
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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

  Future<void> addBall(DateTime date, BallInfo ballInfo) async {
    final balls = await loadBalls(date);
    balls.add(ballInfo);
    await saveBalls(date, balls);
  }

  Future<void> saveNewBallInfos(List<BallInfo> newBallInfos) async {
    final prefs = await SharedPreferences.getInstance();
    final newBallInfosJson = jsonEncode(newBallInfos.map((b) => b.toJson()).toList());
    await prefs.setString('new_ball_infos', newBallInfosJson);
  }

  Future<List<BallInfo>> loadNewBallInfos() async {
    final prefs = await SharedPreferences.getInstance();
    final newBallInfosJson = prefs.getString('new_ball_infos');
    if (newBallInfosJson != null) {
      final List<dynamic> decodedList = jsonDecode(newBallInfosJson);
      return decodedList.map((json) => BallInfo.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> clearNewBallInfos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('new_ball_infos');
  }

  Future<void> saveAllBallsPositions(List<BallInfo> balls) async {
    final prefs = await SharedPreferences.getInstance();
    final ballPositions = balls.map((ball) => {
      'x': ball.x,
      'y': ball.y,
      'color': ball.color.value,
      'radius': ball.radius,
      'createdAt': ball.createdAt.toIso8601String(),
    }).toList();
    await prefs.setString('all_balls_positions', jsonEncode(ballPositions));
  }

  Future<List<BallInfo>> loadAllBallsPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final positionsJson = prefs.getString('all_balls_positions');
    if (positionsJson != null) {
      final List<dynamic> positions = jsonDecode(positionsJson);
      return positions.map((pos) => BallInfo(
        createdAt: DateTime.parse(pos['createdAt']),
        color: Color(pos['color']),
        radius: pos['radius'],
        x: pos['x'],
        y: pos['y'],
      )).toList();
    }
    return [];
  }

  Future<void> clearAllMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('memos_')) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> clearAllBalls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('all_balls_positions');
  }
}
