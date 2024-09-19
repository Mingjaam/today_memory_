class SharedMemo {
  final String text;
  final String emoji;
  final DateTime createdAt;
  final DateTime date;

  SharedMemo({
    required this.text,
    required this.emoji,
    required this.createdAt,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'emoji': emoji,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory SharedMemo.fromJson(Map<String, dynamic> json) => SharedMemo(
    text: json['text'],
    emoji: json['emoji'],
    date: DateTime.parse(json['date']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}