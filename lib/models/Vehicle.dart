class Vehicle {
  final String vehicleReg;
  final String vehicleModel;
  final String vehicleType;
  final String vehicleStatus;
  final int vehicleOwner;
  final String MediaType;
  final String MediaPath;
  final String MediaName;
  final String? OwnerName;

  Vehicle({
    required this.vehicleReg,
    required this.vehicleModel,
    required this.vehicleType,
    required this.vehicleStatus,
    required this.vehicleOwner,
    required this.MediaName,
    required this.MediaPath,
    required this.MediaType,
    this.OwnerName
  });

  factory Vehicle.fromMap(Map<String, dynamic> json) {
    return Vehicle(
      vehicleReg: json['VehicleReg'] ?? '',
      vehicleModel: json['VehicleModel'] ?? '',
      vehicleType: json['VehicleType'] ?? '',
      vehicleStatus: json['VehicleStatus'] ?? '',
      vehicleOwner: json['VehicleOwner'] ?? 0,
      MediaName: json['MediaName'] ?? '',
      MediaPath: json['MediaPath'] ?? '',
      MediaType: json['MediaType'] ?? '',
      OwnerName: json['OwnerName']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "VehicleReg": vehicleReg,
      "VehicleModel": vehicleModel,
      "VehicleType": vehicleType,
      "VehicleStatus": vehicleStatus,
      "VehicleOwner": vehicleOwner,
      "MediaName": MediaName,
      "MediaPath":MediaPath,
      "MediaType":MediaType,
      "OwnerName":OwnerName
    };
  }
}
