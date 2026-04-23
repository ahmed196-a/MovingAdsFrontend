import 'dart:convert';
import 'package:ads_frontend/services/ipAddress.dart';
import 'package:http/http.dart' as http;
import '../models/AdFence.dart';
import '../models/matched_driver_grouped_dto.dart';

class AdFenceApiService {
  static const String baseUrl = "http://${IpAddress.ip}/MovingAdsBackend/api/adfence";

  // ✅ GET All
  static Future<List<AdFence>> getAllFences() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => AdFence.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load fences");
    }
  }

  // ✅ GET by AdId
  static Future<List<AdFence>> getFenceByAd(int adId) async {
    final response =
    await http.get(Uri.parse("$baseUrl/ad/$adId"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => AdFence.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load fence");
    }
  }

  // ✅ POST Fence
  static Future<bool> addFence(AdFence fence) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addfence'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(fence.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Optional: log response body for debugging
        throw Exception(
          'Failed to add fence. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      // Network / parsing / unexpected errors
      throw Exception('Error adding fence: $e');
    }
  }

  static Future<List<String>> matchDrivers(int adId) async {

    final response = await http.get(
      Uri.parse("$baseUrl/matchdrivers/$adId"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {

      List<dynamic> data = jsonDecode(response.body);

      // Convert dynamic list to List<String>
      return data.map((e) => e.toString()).toList();

    } else {
      throw Exception("Failed to fetch matched drivers");
    }
  }

  static Future<List<MatchedDriverGroupedDTO>> matchDrivers3(int adId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/matchdrivers3/$adId"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => MatchedDriverGroupedDTO.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch matched drivers");
    }
  }

}
