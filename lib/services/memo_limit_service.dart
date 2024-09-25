import 'package:shared_preferences/shared_preferences.dart';

class MemoLimitService {
  static const int DEFAULT_LIMIT = 12;
  static const int MAX_LIMIT = 15;

  Future<int> getMemoLimit(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_getKey(date)) ?? DEFAULT_LIMIT;
  }

  Future<int> increaseMemoLimit(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    int currentLimit = prefs.getInt(_getKey(date)) ?? DEFAULT_LIMIT;
    if (currentLimit < MAX_LIMIT) {
      currentLimit++;
      await prefs.setInt(_getKey(date), currentLimit);
    }
    return currentLimit;
  }

  String _getKey(DateTime date) {
    return 'memo_limit_${date.year}_${date.month}_${date.day}';
  }
}