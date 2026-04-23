class DailyTrip {
  final int tripId;
  final String vehicleReg;
  final int adId;
  final DateTime tripDate;
  final double validDistanceKm;
  final double validTimeMinutes;
  final int segmentsCount;
  final DateTime updatedAt;

  // joined
  final String vehicleModel;
  final String driverName;
  final String adTitle;
  final double amountDue;

  DailyTrip({
    required this.tripId,
    required this.vehicleReg,
    required this.adId,
    required this.tripDate,
    required this.validDistanceKm,
    required this.validTimeMinutes,
    required this.segmentsCount,
    required this.updatedAt,
    required this.vehicleModel,
    required this.driverName,
    required this.adTitle,
    required this.amountDue,
  });

  factory DailyTrip.fromJson(Map<String, dynamic> json) {
    return DailyTrip(
      tripId:            json['TripId']           ?? 0,
      vehicleReg:        json['VehicleReg']        ?? '',
      adId:              json['AdId']              ?? 0,
      tripDate:          DateTime.parse(json['TripDate']),
      validDistanceKm:   (json['ValidDistanceKm']  ?? 0).toDouble(),
      validTimeMinutes:  (json['ValidTimeMinutes'] ?? 0).toDouble(),
      segmentsCount:     json['SegmentsCount']     ?? 0,
      updatedAt:         DateTime.parse(json['UpdatedAt']),
      vehicleModel:      json['VehicleModel']      ?? '',
      driverName:        json['DriverName']        ?? '',
      adTitle:           json['AdTitle']           ?? '',
      amountDue:         (json['AmountDue']        ?? 0).toDouble(),
    );
  }
}