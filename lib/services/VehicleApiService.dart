import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/vehicle.dart';
import '././ipAddress.dart';

class VehicleApiService {
  static const String baseUrl =
      "http://${IpAddress.ip}/MovingAdsBackend/api/vehicle";

  // base for non-vehicle routes (agency, tracking)
  static const String _apiBase =
      "http://${IpAddress.ip}/MovingAdsBackend/api";

  // ─────────────────────────────────────────────────────────────────────────────
  // EXISTING — unchanged
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<List<Vehicle>> fetchVehicles(int ownerId) async {
    final response = await http.get(Uri.parse("$baseUrl/owner/$ownerId"));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Vehicle.fromMap(e)).toList();
    }
    throw Exception(response.body);
  }

  static Future<bool> registerVehicle(Vehicle vehicle) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(vehicle.toMap()),
    );
    return response.statusCode == 200;
  }

  static const String cloudName    = "dypza1fuj";
  static const String uploadPreset = "MovingAds";

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
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    var response     = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseData)['secure_url'];
    }
    return null;
  }

  static Future<bool> registerVehicle2({
    required String vehicleReg,
    required String vehicleModel,
    required String vehicleType,
    required int vehicleOwner,
    required File mediaFile,
    required String mediaType,
  }) async {
    String? mediaUrl = await uploadToCloudinary(mediaFile, mediaType);
    if (mediaUrl == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "VehicleReg":    vehicleReg,
        "VehicleModel":  vehicleModel,
        "VehicleType":   vehicleType,
        "VehicleStatus": "offline",
        "VehicleOwner":  vehicleOwner,
        "MediaName":     mediaFile.path.split('/').last,
        "MediaPath":     mediaUrl,
        "MediaType":     mediaType,
      }),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<Vehicle>> fetchVehiclesByRegs(List<String> regs) async {
    final response = await http.post(
      Uri.parse("$baseUrl/byregs"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(regs),
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Vehicle.fromMap(e)).toList();
    }
    throw Exception("Failed to fetch vehicles");
  }

  static Future<List<Vehicle>> fetchVehiclesByAgency(int agencyid) async {
    final response= await http.get(Uri.parse("$baseUrl/agency/$agencyid"));
    if(response.statusCode==200){
      List data=jsonDecode(response.body);
      return data.map((e) => Vehicle.fromMap(e)).toList();
    }
    else{
      throw Exception("Failed to fetch vehicles");
    }
  }

  static Future<bool> isVehicleLinkedToAgency({
    required String vehicleReg,
    required int agencyId,
  }) async {
    try {
      final uri = Uri.parse(
        '$_apiBase/agency/vehicle/isLinked'
            '?vehicleReg=${Uri.encodeComponent(vehicleReg)}&agencyId=$agencyId',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['isLinked'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Original link — sends full Vehicle object, no GPS.
  /// Keep for backward compatibility with existing screens.
  static Future<void> linkVehicleToAgency({
    required Vehicle vehicle,
    required int agencyId,
  }) async {
    final uri = Uri.parse('$_apiBase/agency/vehicle/link');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'VehicleReg':    vehicle.vehicleReg,
        'VehicleModel':  vehicle.vehicleModel,
        'VehicleType':   vehicle.vehicleType,
        'VehicleStatus': vehicle.vehicleStatus,
        'VehicleOwner':  vehicle.vehicleOwner,
        'AgencyId':      agencyId,
        'MediaName':     vehicle.mediaName,
        'MediaPath':     vehicle.mediaPath,
        'MediaType':     vehicle.mediaType,
        'OwnerName':     vehicle.ownerName,
      }),
    );
    if (response.statusCode != 200) {
      String errorMsg = 'Failed to link vehicle.';
      try { errorMsg = jsonDecode(response.body) ?? errorMsg; } catch (_) {}
      throw Exception(errorMsg);
    }
  }
}