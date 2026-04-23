import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/daily_trip.dart';
import 'ipAddress.dart';

class TrackingApiService {
  static const String baseUrl =
      "http://${IpAddress.ip}/MovingAdsBackend/api/tracking";

  // ── POST a GPS ping from the driver app ──────────────────
  // Call this every 2-3 minutes when driver is online.
  // Returns a message string from backend.
  static Future<String> logLocation({
    required String vehicleReg,
    required int userId,
    required int adId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/log"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "VehicleReg": vehicleReg,
          "UserId":     userId,
          "AdId":       adId,
          "Latitude":   latitude,
          "Longitude":  longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? "Logged";
      } else {
        return "Failed: ${response.body}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  // ── GET all daily trips for an ad (advertiser view) ──────
  static Future<List<DailyTrip>> getDailyTripsByAd(int adId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/dailytrip/$adId"),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => DailyTrip.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load daily trips");
    }
  }

  // ── GET driver's own trips by vehicle reg ────────────────
  static Future<List<DailyTrip>> getMyTrips(String vehicleReg) async {
    final response = await http.get(
      Uri.parse("$baseUrl/mytrips/$vehicleReg"),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => DailyTrip.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load my trips");
    }
  }
}


