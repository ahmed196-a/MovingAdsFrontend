class Vehicle {
  final String vehicleReg;
  final String vehicleModel;
  final String vehicleType;
  final String vehicleStatus;
  final int vehicleOwner;
  final int? agencyId;          // ← NEW (nullable: 0 or null = not linked)
  final String mediaType;
  final String mediaPath;
  final String mediaName;
  final String? ownerName;

  Vehicle({
    required this.vehicleReg,
    required this.vehicleModel,
    required this.vehicleType,
    required this.vehicleStatus,
    required this.vehicleOwner,
    this.agencyId,
    required this.mediaName,
    required this.mediaPath,
    required this.mediaType,
    this.ownerName,
  });

  factory Vehicle.fromMap(Map<String, dynamic> json) {
    // AgencyId of 0 from backend means "not linked" → treat as null
    final rawAgency = json['AgencyId'];
    return Vehicle(
      vehicleReg:    json['VehicleReg']    ?? '',
      vehicleModel:  json['VehicleModel']  ?? '',
      vehicleType:   json['VehicleType']   ?? '',
      vehicleStatus: json['VehicleStatus'] ?? '',
      vehicleOwner:  json['VehicleOwner']  ?? 0,
      agencyId:      (rawAgency == null || rawAgency == 0) ? null : rawAgency as int,
      mediaName:     json['MediaName']     ?? '',
      mediaPath:     json['MediaPath']     ?? '',
      mediaType:     json['MediaType']     ?? '',
      ownerName:     json['OwnerName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'VehicleReg':    vehicleReg,
      'VehicleModel':  vehicleModel,
      'VehicleType':   vehicleType,
      'VehicleStatus': vehicleStatus,
      'VehicleOwner':  vehicleOwner,
      'AgencyId':      agencyId ?? 0,
      'MediaName':     mediaName,
      'MediaPath':     mediaPath,
      'MediaType':     mediaType,
      'OwnerName':     ownerName,
    };
  }
}