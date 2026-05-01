class TimeSlotModel {
  final String id;
  final DateTime date;
  final String time;
  final bool isAvailable;

  TimeSlotModel({
    required this.id,
    required this.date,
    required this.time,
    required this.isAvailable,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T').first,
      'time': time,
      'is_available': isAvailable,
    };
  }
}
