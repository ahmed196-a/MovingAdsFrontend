import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/adSchedule.dart';
import 'ipAddress.dart';


class AdScheduleApiService {
  static const String baseUrl = "http://${IpAddress.ip}/MovingAdsBackend/api/adSchedule";

  static Future<bool> saveSchedule(List<AdScheduleModel> schedules) async {
    List<Map<String,dynamic>> data =
    schedules.map((e) => e.toJson()).toList();

    var response = await http.post(
      Uri.parse('$baseUrl/save'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if(response.statusCode == 200){
      return true;
    }
    return false;
  }

}