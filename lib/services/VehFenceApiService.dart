import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/VehFence.dart';
import '././ipAddress.dart';

class VehFenceApiService {

  static const String baseUrl = "http://${IpAddress.ip}/MovingAdsBackend/api/vehfence";

  // ✅ GET All
  static Future<List<VehFence>> getAllFences() async {
    final response = await http.get(Uri.parse("$baseUrl/getallfences"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => VehFence.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load fences");
    }
  }

  // ✅ GET by VehicleReg
  static Future<List<VehFence>> getFenceByVehicle(String vehicleReg) async {
    final response =
    await http.get(Uri.parse("$baseUrl/vehicle/$vehicleReg"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => VehFence.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load fence");
    }
  }

  // ✅ POST Fence
  static Future<bool> addFence(VehFence fence) async {
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

}
