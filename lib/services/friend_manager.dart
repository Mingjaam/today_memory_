import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend.dart';

class FriendManager {
  static const String _key = 'friends';

  static Future<List<Friend>> getFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = prefs.getStringList(_key) ?? [];
    return friendsJson.map((json) => Friend.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> addFriend(Friend friend) async {
    final prefs = await SharedPreferences.getInstance();
    final friendsJson = prefs.getStringList(_key) ?? [];
    friendsJson.add(jsonEncode(friend.toJson()));
    await prefs.setStringList(_key, friendsJson);
  }
}
