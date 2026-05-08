import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/adAssignment.dart';
import '../models/agency.dart';
import 'ipAddress.dart';

class AgencyApiService {
  static const String baseUrl = "http://${IpAddress.ip}/MovingAdsBackend/api";

  // GET api/agency/byuser/{userId}
  static Future<Agency> getAgencyByUserId(int userId) async {
    final url = Uri.parse('$baseUrl/agency/byuser/$userId');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return Agency.fromJson(jsonDecode(res.body));
      }
      throw Exception('Agency not found (status: ${res.statusCode})');
    } catch (e) {
      throw Exception('getAgencyByUserId failed: $e');
    }
  }

  // GET api/agency/byid/{agencyId}
  static Future<Agency> getAgencyById(int agencyId) async {
    final url = Uri.parse('$baseUrl/agency/byid/$agencyId');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        return Agency.fromJson(jsonDecode(res.body));
      }
      throw Exception('Agency not found (status: ${res.statusCode})');
    } catch (e) {
      throw Exception('getAgencyById failed: $e');
    }
  }

  // GET api/agencyadassignment/byagency/{agencyId}
  static Future<List<AdAssignment>> getAssignmentsByAgency(int agencyId) async {
    final url = Uri.parse('$baseUrl/adassignment/activebyagency/$agencyId');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => AdAssignment.fromJson(e)).toList();
      }
      throw Exception('Failed to load assignments (status: ${res.statusCode})');
    } catch (e) {
      throw Exception('getAssignmentsByAgency failed: $e');
    }
  }

  // GET api/agency/all
  static Future<List<Agency>> getAllAgencies() async {
    final url = Uri.parse('$baseUrl/agency/all');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Agency.fromJson(e)).toList();
      }
      throw Exception('Failed to load agencies (status: ${res.statusCode})');
    } catch (e) {
      throw Exception('getAllAgencies failed: $e');
    }
  }

  // PUT api/agency/vehicle/link
  // Body: { VehicleReg, AgencyId }
  static Future<void> linkVehicleToAgency(String vehicleReg, int agencyId) async {
    final url = Uri.parse('$baseUrl/agency/vehicle/link');
    try {
      final res = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'VehicleReg': vehicleReg,
          'AgencyId': agencyId,
        }),
      );
      if (res.statusCode != 200) {
        throw Exception(jsonDecode(res.body)['Message'] ?? 'Failed to link vehicle');
      }
    } catch (e) {
      throw Exception('linkVehicleToAgency failed: $e');
    }
  }
}