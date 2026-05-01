class AppointmentModel {
  final String id;
  final String userId;
  final String userName;
  final DateTime date;
  final String timeSlot;
  final String status;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      date: DateTime.parse(json['date'] as String),
      timeSlot: json['time_slot'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'date': date.toIso8601String().split('T').first,
      'time_slot': timeSlot,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
