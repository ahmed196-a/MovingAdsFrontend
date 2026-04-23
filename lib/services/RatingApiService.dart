import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rating.dart';
import 'ipAddress.dart';

class RatingApiService {
  static const String baseUrl = "http://${IpAddress.ip}/MovingAdsBackend/";

  static Future<ApiResult> addRating(Rating model) async {
    try {
      final url = Uri.parse("${baseUrl}api/rating/add");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(model.toJson()),
      );

      // Your controller returns Ok("...") or BadRequest("...")
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return ApiResult(success: true, message: _tryReadMessage(res.body));
      } else {
        return ApiResult(success: false, message: _tryReadMessage(res.body));
      }
    } catch (e) {
      return ApiResult(success: false, message: e.toString());
    }
  }

  static String _tryReadMessage(String body) {
    // If your API sometimes returns plain string, sometimes JSON
    try {
      final decoded = jsonDecode(body);
      if (decoded is String) return decoded;
      if (decoded is Map && decoded["Message"] != null) return decoded["Message"].toString();
      return body;
    } catch (_) {
      return body;
    }
  }
}

class ApiResult {
  final bool success;
  final String message;

  ApiResult({required this.success, required this.message});
}