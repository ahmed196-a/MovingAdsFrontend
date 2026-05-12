// ─────────────────────────────────────────────────────────────────
//  Model — AgencyBilling
//  Matches BillingController DTOs and AgencyBilling model
// ─────────────────────────────────────────────────────────────────

class AgencyBilling {
  final int billingId;
  final int agencyId;
  final String agencyName;
  final double advertiserRate;
  final double driverRate;

  AgencyBilling({
    required this.billingId,
    required this.agencyId,
    required this.agencyName,
    required this.advertiserRate,
    required this.driverRate,
  });

  factory AgencyBilling.fromJson(Map<String, dynamic> json) {
    return AgencyBilling(
      billingId: _toInt(json['BillingId']),
      agencyId: _toInt(json['AgencyId']),
      agencyName: json['AgencyName']?.toString() ?? '',
      advertiserRate: _toDouble(json['AdvertiserRate']),
      driverRate: _toDouble(json['DriverRate']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// ── Partial responses for rate-only endpoints ─────────────────────

class AdvertiserRateResponse {
  final int billingId;
  final int agencyId;
  final String agencyName;
  final double advertiserRate;

  AdvertiserRateResponse({
    required this.billingId,
    required this.agencyId,
    required this.agencyName,
    required this.advertiserRate,
  });

  factory AdvertiserRateResponse.fromJson(Map<String, dynamic> json) {
    return AdvertiserRateResponse(
      billingId: AgencyBilling._toInt(json['BillingId']),
      agencyId: AgencyBilling._toInt(json['AgencyId']),
      agencyName: json['AgencyName']?.toString() ?? '',
      advertiserRate: AgencyBilling._toDouble(json['AdvertiserRate']),
    );
  }
}

class DriverRateResponse {
  final int billingId;
  final int agencyId;
  final String agencyName;
  final double driverRate;

  DriverRateResponse({
    required this.billingId,
    required this.agencyId,
    required this.agencyName,
    required this.driverRate,
  });

  factory DriverRateResponse.fromJson(Map<String, dynamic> json) {
    return DriverRateResponse(
      billingId: AgencyBilling._toInt(json['BillingId']),
      agencyId: AgencyBilling._toInt(json['AgencyId']),
      agencyName: json['AgencyName']?.toString() ?? '',
      driverRate: AgencyBilling._toDouble(json['DriverRate']),
    );
  }
}