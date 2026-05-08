import 'dart:convert';
import 'package:ads_frontend/models/simulation_models.dart';
import 'package:ads_frontend/services/ipAddress.dart';
import 'package:http/http.dart' as http;

class SimulationApiService {
  static const String baseUrl =
      "http://${IpAddress.ip}/MovingAdsBackend/api/simulation";

  // ══════════════════════════════════════════════════════════════
  //  POST  api/simulation/saveactivity
  //  Sends a location ping every 30 seconds from the driver app.
  // ══════════════════════════════════════════════════════════════
  static Future<ActivityLogResponse> saveDriverActivityLog(
      ActivityLogRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/saveactivity'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return ActivityLogResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to save activity log. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error saving activity log: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  GET  api/simulation/allocatedtime/{adId}
  //  Returns total allocated minutes for an ad based on its
  //  schedule, day-of-week flags, and campaign date range.
  // ══════════════════════════════════════════════════════════════
  static Future<AllocatedTimeResponse> getAllocatedTime(int adId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/allocatedtime/$adId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AllocatedTimeResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load allocated time. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching allocated time: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  GET  api/simulation/analytics/{adId}
  //  Allocated / consumed / remaining time + km + daily summaries.
  // ══════════════════════════════════════════════════════════════
  static Future<AdAnalyticsResponse> getAdAnalytics(int adId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/$adId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AdAnalyticsResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load ad analytics. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching ad analytics: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  GET  api/simulation/drivertrips/{driverId}
  //  All daily trips for a specific driver.
  // ══════════════════════════════════════════════════════════════
  static Future<List<DriverTripSummary>> getDriverTrips(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drivertrips/$driverId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => DriverTripSummary.fromJson(e)).toList();
      } else {
        throw Exception(
          'Failed to load driver trips. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching driver trips: $e');
    }
  }
}