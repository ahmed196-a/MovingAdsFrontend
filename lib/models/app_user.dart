class AppUser {
  int? userId;
  String name;
  String email;
  String password;
  double? rating;
  String role;

  AppUser({
    this.userId,
    required this.name,
    required this.email,
    required this.password,
    this.rating,
    required this.role,
  });

  /// API → Flutter
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['UserId'],
      name: map['Name'],
      email: map['Email'],
      password: '',
      rating: map['Rating'] != null
          ? double.parse(map['Rating'].toString())
          : 0.0,
      role: map['role'],
    );
  }

  /// Flutter → API
  Map<String, dynamic> toMap() {
    return {
      "Name": name,
      "Email": email,
      "Password": password,
      "role": role,
    };
  }
}
