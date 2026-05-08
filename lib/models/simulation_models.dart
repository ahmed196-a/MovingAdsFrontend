// ─────────────────────────────────────────────────────────────────
//  Models — SimulationController DTOs
// ─────────────────────────────────────────────────────────────────

// ── ActivityLogRequest ────────────────────────────────────────────
class ActivityLogRequest {
  final int driverId;
  final String vehicleReg;
  final int adId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  ActivityLogRequest({
    required this.driverId,
    required this.vehicleReg,
    required this.adId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'DriverId': driverId,
      'VehicleReg': vehicleReg,
      'AdId': adId,
      'Latitude': latitude,
      'Longitude': longitude,
      'RecordedAt': recordedAt.toIso8601String(),
    };
  }
}

// ── ActivityLogResponse ───────────────────────────────────────────
class ActivityLogResponse {
  final bool isValid;
  final String message;
  final int? dailyTripId;
  final double totalValidKm;
  final double totalValidMin;

  ActivityLogResponse({
    required this.isValid,
    required this.message,
    this.dailyTripId,
    required this.totalValidKm,
    required this.totalValidMin,
  });

  factory ActivityLogResponse.fromJson(Map<String, dynamic> json) {
    return ActivityLogResponse(
      isValid: json['IsValid'] == true,
      message: json['Message']?.toString() ?? '',
      dailyTripId:
      json['DailyTripId'] == null ? null : _toInt(json['DailyTripId']),
      totalValidKm: _toDouble(json['TotalValidKm']),
      totalValidMin: _toDouble(json['TotalValidMin']),
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

// ── DailyTripSummary ──────────────────────────────────────────────
class DailyTripSummary {
  final int tripId;
  final String vehicleReg;
  final DateTime tripDate;
  final double validDistanceKm;
  final double validTimeMinutes;
  final int segmentsCount;

  DailyTripSummary({
    required this.tripId,
    required this.vehicleReg,
    required this.tripDate,
    required this.validDistanceKm,
    required this.validTimeMinutes,
    required this.segmentsCount,
  });

  factory DailyTripSummary.fromJson(Map<String, dynamic> json) {
    return DailyTripSummary(
      tripId: _toInt(json['TripId']),
      vehicleReg: json['VehicleReg']?.toString() ?? '',
      tripDate: json['TripDate'] != null
          ? DateTime.tryParse(json['TripDate'].toString()) ?? DateTime(2000)
          : DateTime(2000),
      validDistanceKm: _toDouble(json['ValidDistanceKm']),
      validTimeMinutes: _toDouble(json['ValidTimeMinutes']),
      segmentsCount: _toInt(json['SegmentsCount']),
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

// ── AdAnalyticsResponse ───────────────────────────────────────────
class AdAnalyticsResponse {
  final int adId;
  final String adTitle;
  final double allocatedMinutes;
  final double consumedMinutes;
  final double remainingMinutes;
  final double totalValidKm;
  final List<DailyTripSummary> dailyTrips;

  AdAnalyticsResponse({
    required this.adId,
    required this.adTitle,
    required this.allocatedMinutes,
    required this.consumedMinutes,
    required this.remainingMinutes,
    required this.totalValidKm,
    required this.dailyTrips,
  });

  factory AdAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return AdAnalyticsResponse(
      adId: _toInt(json['AdId']),
      adTitle: json['AdTitle']?.toString() ?? '',
      allocatedMinutes: _toDouble(json['AllocatedMinutes']),
      consumedMinutes: _toDouble(json['ConsumedMinutes']),
      remainingMinutes: _toDouble(json['RemainingMinutes']),
      totalValidKm: _toDouble(json['TotalValidKm']),
      dailyTrips: json['DailyTrips'] != null
          ? (json['DailyTrips'] as List)
          .map((e) => DailyTripSummary.fromJson(e))
          .toList()
          : [],
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

// ── AllocatedTimeResponse ─────────────────────────────────────────
/// Matches the anonymous object returned by GET api/simulation/allocatedtime/{adId}
class AllocatedTimeResponse {
  final int adId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double allocatedMinutes;
  final double allocatedHours;

  AllocatedTimeResponse({
    required this.adId,
    this.startDate,
    this.endDate,
    required this.allocatedMinutes,
    required this.allocatedHours,
  });

  factory AllocatedTimeResponse.fromJson(Map<String, dynamic> json) {
    return AllocatedTimeResponse(
      adId: _toInt(json['AdId']),
      startDate: json['StartDate'] != null
          ? DateTime.tryParse(json['StartDate'].toString())
          : null,
      endDate: json['EndDate'] != null
          ? DateTime.tryParse(json['EndDate'].toString())
          : null,
      allocatedMinutes: _toDouble(json['AllocatedMinutes']),
      allocatedHours: _toDouble(json['AllocatedHours']),
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

// ── DriverTripSummary ─────────────────────────────────────────────
/// Matches the anonymous object returned by GET api/simulation/drivertrips/{driverId}
class DriverTripSummary {
  final int tripId;
  final String vehicleReg;
  final int adId;
  final String adTitle;
  final DateTime tripDate;
  final double validDistanceKm;
  final double validTimeMinutes;
  final int segmentsCount;

  DriverTripSummary({
    required this.tripId,
    required this.vehicleReg,
    required this.adId,
    required this.adTitle,
    required this.tripDate,
    required this.validDistanceKm,
    required this.validTimeMinutes,
    required this.segmentsCount,
  });

  factory DriverTripSummary.fromJson(Map<String, dynamic> json) {
    return DriverTripSummary(
      tripId: _toInt(json['TripId']),
      vehicleReg: json['VehicleReg']?.toString() ?? '',
      adId: _toInt(json['AdId']),
      adTitle: json['AdTitle']?.toString() ?? '',
      tripDate: json['TripDate'] != null
          ? DateTime.tryParse(json['TripDate'].toString()) ?? DateTime(2000)
          : DateTime(2000),
      validDistanceKm: _toDouble(json['ValidDistanceKm']),
      validTimeMinutes: _toDouble(json['ValidTimeMinutes']),
      segmentsCount: _toInt(json['SegmentsCount']),
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