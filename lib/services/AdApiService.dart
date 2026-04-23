import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/Ad.dart';
import '../models/adAssignment.dart';
import '././ipAddress.dart';

class AdApiService {
  static const String baseUrl = "http://${IpAddress.ip}/MovingAdsBackend/";

  static Future<List<Ad>> fetchAds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ad/GetAllAds'),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Ad.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load ads");
    }
  }

  static Future<List<Ad>> fetchAdsByUser(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/ad/GetAdsByUser/$userId'),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Ad.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load ads");
    }
  }


  static const String cloudName = "dypza1fuj";
  static const String uploadPreset = "MovingAds";

  static Future<String?> uploadToCloudinary(File file, String mediaType) async {
    final resourceType = mediaType == "video" ? "video" : "image";

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

  static Future<bool> postAd({
    required String title,
    required String mediaType,
    required String category,
    required DateTime startingDate,
    required DateTime endingDate,
    required int userId,
    required File mediaFile,
    required String status,
  }) async {

    // STEP 1: Upload to Cloudinary
    String? mediaUrl = await uploadToCloudinary(mediaFile, mediaType);

    if (mediaUrl == null) {
      return false;
    }

    // STEP 2: Send URL to backend
    final response = await http.post(
      Uri.parse('${baseUrl}api/ad/createAd'),
      headers: {
        "Content-Type": "application/json",
      },
      body: json.encode({
        "AdTitle": title,
        "MediaType": mediaType,
        "MediaName": mediaFile.path.split('/').last,
        "MediaPath": mediaUrl, // 👈 SAVE CLOUDINARY URL
        "UserId": userId,
        "Category": category,
        "StartingDate": startingDate.toString().split(' ')[0],
        "EndingDate": endingDate.toString().split(' ')[0],
        "Status": status,
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<Ad?> getAdById(int id) async {
    final response =
    await http.get(Uri.parse("$baseUrl/api/ad/GetAdByid/$id"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Ad.fromJson(data);
    } else {
      return null;
    }
  }

  static Future<List<AdAssignment>> getAssignedDrivers(int adId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/adassignment/byad/$adId"),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => AdAssignment.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load assigned drivers");
    }
  }

  static Future<bool> pauseAd(int adId) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/adassignment/pause/$adId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"AdId": adId}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> resumeAd(int adId) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/adassignment/resume/$adId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"AdId": adId}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> terminateAd(int adId) async {
    final response = await http.put(
      Uri.parse("$baseUrl/api/adassignment/terminate/$adId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"AdId": adId}),
    );

    return response.statusCode == 200;
  }

  static Future<bool> republishAd(Ad ad) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/adassignment/republish"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "AdTitle": ad.adTitle,
        "MediaType": ad.mediaType,
        "MediaName": ad.mediaName,
        "MediaPath": ad.mediaPath,
        "UserId": ad.userId,
        "StartingDate": ad.StartingDate.toString().split(' ')[0],
        "EndingDate": ad.EndingDate.toString().split(' ')[0],
        "Category": ad.Category,
        "Status": ad.status, // optional but safer
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }
}
