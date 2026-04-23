class BillingRecord {
  final int billId;
  final int tripId;
  final int adId;
  final String vehicleReg;
  final DateTime billDate;
  final double validDistanceKm;
  final double validTimeMinutes;
  final double amountDue;
  final String status; // unpaid | paid | disputed

  // joined
  final String driverName;
  final String vehicleModel;
  final String adTitle;

  BillingRecord({
    required this.billId,
    required this.tripId,
    required this.adId,
    required this.vehicleReg,
    required this.billDate,
    required this.validDistanceKm,
    required this.validTimeMinutes,
    required this.amountDue,
    required this.status,
    required this.driverName,
    required this.vehicleModel,
    required this.adTitle,
  });

  factory BillingRecord.fromJson(Map<String, dynamic> json) {
    return BillingRecord(
      billId:           json['BillId']           ?? 0,
      tripId:           json['TripId']           ?? 0,
      adId:             json['AdId']             ?? 0,
      vehicleReg:       json['VehicleReg']        ?? '',
      billDate:         DateTime.parse(json['BillDate']),
      validDistanceKm:  (json['ValidDistanceKm']  ?? 0).toDouble(),
      validTimeMinutes: (json['ValidTimeMinutes'] ?? 0).toDouble(),
      amountDue:        (json['AmountDue']        ?? 0).toDouble(),
      status:           json['Status']            ?? 'unpaid',
      driverName:       json['DriverName']        ?? '',
      vehicleModel:     json['VehicleModel']      ?? '',
      adTitle:          json['AdTitle']           ?? '',
    );
  }
}
