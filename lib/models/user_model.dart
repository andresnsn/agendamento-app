class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isAdmin;
  final String? authProvider;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.isAdmin = false,
    this.authProvider,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      authProvider: json['auth_provider'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'is_admin': isAdmin,
      'auth_provider': authProvider,
    };
  }
}
