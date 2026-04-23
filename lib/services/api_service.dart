import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_user.dart';
import '././ipAddress.dart';

class ApiService {
  static const String baseUrl = "http://${IpAddress.ip}/MovingAdsBackend/";

  /// ---------------- SIGNUP ----------------
  static Future<String> signup(AppUser user) async {
    final url = Uri.parse("${baseUrl}api/user/signup");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(user.toMap()),
    );

    if (response.statusCode == 200) {
      return "success";
    } else {
      return response.body.replaceAll('"', '');
    }
  }

  /// ---------------- LOGIN ----------------
  static Future<AppUser?> login(String email, String password) async {
    final url =
    Uri.parse("${baseUrl}api/user/login/$email/$password");

    final response = await http.post(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppUser.fromMap(data);
    } else {
      return null;
    }
  }
}
