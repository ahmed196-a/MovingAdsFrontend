import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/billing_record.dart';
import '../models/billing_rate.dart';
import '../models/ad_billing_summary.dart';
import 'ipAddress.dart';

class BillingApiService {
  static const String baseUrl =
      "http://${IpAddress.ip}/MovingAdsBackend/api/billing";

  // ── POST create billing rate for an ad ───────────────────
  static Future<bool> createRate(BillingRate rate) async {
    final response = await http.post(
      Uri.parse("$baseUrl/rate"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(rate.toJson()),
    );
    return response.statusCode == 200;
  }

  // ── GET billing rate for an ad ───────────────────────────
  // Returns null if no rate has been set yet
  static Future<BillingRate?> getRate(int adId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/rate/$adId"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) return null;
      return BillingRate.fromJson(data);
    } else {
      throw Exception("Failed to load billing rate");
    }
  }

  // ── PUT update billing rate ───────────────────────────────
  static Future<bool> updateRate(int adId, BillingRate rate) async {
    final response = await http.put(
      Uri.parse("$baseUrl/rate/$adId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(rate.toJson()),
    );
    return response.statusCode == 200;
  }

  // ── GET all billing records for an ad (advertiser) ───────
  static Future<List<BillingRecord>> getRecordsByAd(int adId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/records/$adId"),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => BillingRecord.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load billing records");
    }
  }

  // ── GET driver earnings by vehicle reg ───────────────────
  static Future<List<BillingRecord>> getMyEarnings(String vehicleReg) async {
    final response = await http.get(
      Uri.parse("$baseUrl/myearnings/$vehicleReg"),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => BillingRecord.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load earnings");
    }
  }

  // ── GET summary totals for an ad ─────────────────────────
  static Future<AdBillingSummary> getAdSummary(int adId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/summary/$adId"),
    );

    if (response.statusCode == 200) {
      return AdBillingSummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Failed to load billing summary");
    }
  }

  // ── PUT mark a bill as paid ───────────────────────────────
  static Future<bool> markAsPaid(int billId) async {
    final response = await http.put(
      Uri.parse("$baseUrl/pay/$billId"),
      headers: {"Content-Type": "application/json"},
    );
    return response.statusCode == 200;
  }
}
