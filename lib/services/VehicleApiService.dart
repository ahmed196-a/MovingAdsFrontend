import 'dart:convert';
import 'dart:io';
import 'package:ads_frontend/services/AdApiService.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/vehicle.dart';
import '././ipAddress.dart';

class VehicleApiService {
  static const String baseUrl = "http://${IpAddress.ip}/MovingAdsBackend/api/vehicle";

  static Future<List<Vehicle>> fetchVehicles(int ownerId) async {
    final response =
    await http.get(Uri.parse("$baseUrl/owner/$ownerId"));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Vehicle.fromMap(e)).toList();
    } else {
      throw Exception(response.body);
    }
  }

  static Future<bool> registerVehicle(Vehicle vehicle) async {

    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(vehicle.toMap()),
    );

    return response.statusCode == 200;
  }
  static const String cloudName = "dypza1fuj";
  static const String uploadPreset = "MovingAds";

  // ================= CLOUDINARY UPLOAD =================

  static Future<String?> uploadToCloudinary(
      File file,
      String mediaType,
      ) async {

    final resourceType =
    mediaType.toLowerCase() == "video" ? "video" : "image";

    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload");

    var request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = uploadPreset;

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseData);
      return data['secure_url'];
    } else {
      print("Cloudinary upload failed");
      return null;
    }
  }

  // ================= REGISTER VEHICLE =================

  static Future<bool> registerVehicle2({
    required String vehicleReg,
    required String vehicleModel,
    required String vehicleType,
    required int vehicleOwner,
    required File mediaFile,
    required String mediaType,
  }) async {

    // STEP 1 → Upload to Cloudinary
    String? mediaUrl =
    await uploadToCloudinary(mediaFile, mediaType);

    if (mediaUrl == null) return false;

    // STEP 2 → Send to backend
    final response = await http.post(
      Uri.parse("${baseUrl}/register"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "VehicleReg": vehicleReg,
        "VehicleModel": vehicleModel,
        "VehicleType": vehicleType,
        "VehicleStatus": "offline",
        "VehicleOwner": vehicleOwner,
        "MediaName": mediaFile.path.split('/').last,
        "MediaPath": mediaUrl,
        "MediaType": mediaType,
      }),
    );

    return response.statusCode == 200 ||
        response.statusCode == 201;
  }

  static Future<List<Vehicle>> fetchVehiclesByRegs(
      List<String> regs) async {

    final response = await http.post(
      Uri.parse("$baseUrl/byregs"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(regs),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);

      return data.map((e) => Vehicle.fromMap(e)).toList();
    } else {
      throw Exception("Failed to fetch vehicles");
    }
  }

}
