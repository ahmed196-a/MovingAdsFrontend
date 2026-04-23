class AdAssignment {
  final int assignId;
  final int adId;
  final String vehicleReg;
  final String vehicleModel;
  final String vehicleType;
  final String driverName;
  final int driverId;
  final int rating;

  AdAssignment({
    required this.assignId,
    required this.adId,
    required this.vehicleReg,
    required this.vehicleModel,
    required this.vehicleType,
    required this.driverName,
    required this.driverId,
    required this.rating,
  });

  factory AdAssignment.fromJson(Map<String, dynamic> json) {
    return AdAssignment(
      assignId: json["AssignId"],
      adId: json["AdId"],
      vehicleReg: json["VehicleReg"],
      vehicleModel: json["VehicleModel"],
      vehicleType: json["VehicleType"],
      driverName: json["DriverName"],
      driverId: json["DriverId"],
      rating: json["Rating"],
    );
  }
}