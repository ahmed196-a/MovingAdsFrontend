import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/request.dart';
import 'ipAddress.dart';



class RequestApiService {

  static const String baseUrl = "http://${IpAddress.ip}/MovingAdsBackend/api/request";

  static Future<String> createRequest(Request request) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/create"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(request.toMap()),
      );

      if (response.statusCode == 200) {
        return "Request Sent Successfully"; // return response.body
      } else {
        return "Failed: ${response.body}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  static Future<bool> existsRequest(Request request) async{
    try{
      final response=await http.post(Uri.parse("$baseUrl/exists"),
        headers: {
        "Content-Type":"application/json",
        },
        body: jsonEncode(request.toMap()),
      );
      if(response.statusCode==200){
        return true;
      }
      else{
        return false;
      }
    }catch(e){
      return false;
    }
  }

  static Future<List<Request>> getReceivedRequests(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/received/$userId"),
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Request.fromMap(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  static Future<List<Request>> getSentRequests(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/sent/$userId"),
      );

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((e) => Request.fromMap(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateRequestStatus({
    required int reqId,
    required int requestedTo,
    required String status,
    required int adId,
    required int agencyId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/status"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "ReqID": reqId,
          "RequestedTo": requestedTo,
          "Status": status,
          "AdId": adId,
          "AgencyId": agencyId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}