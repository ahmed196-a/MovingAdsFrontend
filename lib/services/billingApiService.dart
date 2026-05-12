import 'dart:async';
import 'dart:convert';
import 'package:ads_frontend/services/ipAddress.dart';
import 'package:http/http.dart' as http;

import '../models/agency_billing_models.dart';

class BillingApiService {
  static const String baseUrl =
      "http://${IpAddress.ip}/MovingAdsBackend/api/billing";

  // ══════════════════════════════════════════════════════════════
  //  POST  api/billing/set
  //  Creates or updates both rates for an agency (upsert).
  // ══════════════════════════════════════════════════════════════
  static Future<String> setRates({
    required int agencyId,
    required double advertiserRate,
    required double driverRate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/set'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'AgencyId': agencyId,
          'AdvertiserRate': advertiserRate,
          'DriverRate': driverRate,
        }),
      );

      if (response.statusCode == 200) {
        return response.body.replaceAll('"', '');
      } else {
        throw Exception(
          'Failed to set rates. Status: ${response.statusCode}, Body: ${response
              .body}',
        );
      }
    } catch (e) {
      throw Exception('Error setting billing rates: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  PUT  api/billing/advertiser-rate/{agencyId}
  //  Updates only the advertiser hourly rate.
  // ══════════════════════════════════════════════════════════════
  static Future<String> updateAdvertiserRate({
    required int agencyId,
    required double advertiserRate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/advertiser-rate/$agencyId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'AdvertiserRate': advertiserRate}),
      );

      if (response.statusCode == 200) {
        return response.body.replaceAll('"', '');
      } else {
        throw Exception(
          'Failed to update advertiser rate. Status: ${response
              .statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error updating advertiser rate: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  PUT  api/billing/driver-rate/{agencyId}
  //  Updates only the driver hourly rate.
  // ══════════════════════════════════════════════════════════════
  static Future<String> updateDriverRate({
    required int agencyId,
    required double driverRate,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/driver-rate/$agencyId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'DriverRate': driverRate}),
      );

      if (response.statusCode == 200) {
        return response.body.replaceAll('"', '');
      } else {
        throw Exception(
          'Failed to update driver rate. Status: ${response
              .statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error updating driver rate: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  GET  api/billing/advertiser-rate/{agencyId}
  // ══════════════════════════════════════════════════════════════
  static Future<AdvertiserRateResponse> getAdvertiserRate(int agencyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/advertiser-rate/$agencyId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AdvertiserRateResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load advertiser rate. Status: ${response
              .statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching advertiser rate: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  GET  api/billing/driver-rate/{agencyId}
  // ══════════════════════════════════════════════════════════════
  static Future<DriverRateResponse> getDriverRate(int agencyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver-rate/$agencyId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return DriverRateResponse.fromJson(data);
      } else {
        throw Exception(
          'Failed to load driver rate. Status: ${response
              .statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching driver rate: $e');
    }
  }

  static Future<Map<String, dynamic>> getDriverBilling(
      int vehicleOwnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/driver/$vehicleOwnerId/summary'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load driver billing. '
              'Status: ${response.statusCode}, '
              'Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching driver billing: $e');
    }
  }

  static Future<List<dynamic>> getAdvertiserBilling(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/advertiser/$userId/summary'),
        headers: {'Content-Type': 'application/json  '},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load advertiser billing. '
              'Status: ${response.statusCode}, '
              'Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching advertiser billing: $e');
    }
  }

  static Future<Map<String, dynamic>> getAgencyBilling(int agencyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agency/$agencyId/summary'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      else {
        throw Exception(
          'Failed to load agency billing. '
              'Status: ${response.statusCode}, '
              'Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching agency billing: $e');
    }
  }

  static Future<List<dynamic>> getAgencyBillingforAdvertisers(
      int agencyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agency/$agencyId/advertisers'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      else {
        throw Exception(
          'Failed to load agency billing for advertisers. '
              'Status: ${response.statusCode}, '
              'Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching agency billing for advertisers: $e');
    }
  }

  static Future<List<dynamic>> getAgencyBillingforDrivers(
      int agencyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/agency/$agencyId/drivers'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      else {
        throw Exception(
          'Failed to load agency billing for drivers. '
              'Status: ${response.statusCode}, '
              'Body: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching agency billing for drivers: $e');
    }
  }
}