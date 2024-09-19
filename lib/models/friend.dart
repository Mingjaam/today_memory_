import 'package:flutter/material.dart';

class Friend {
  final String name;
  final Color color;

  Friend({required this.name, required this.color});

  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color.value,
  };

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
    name: json['name'],
    color: Color(json['color']),
  );
}