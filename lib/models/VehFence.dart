class VehFence {
  final int? vehFenceId;
  final String vehicleReg;
  final String polygon;
  final String label;

  VehFence({
    this.vehFenceId,
    required this.vehicleReg,
    required this.polygon,
    required this.label
  });

  factory VehFence.fromJson(Map<String, dynamic> json) {
    return VehFence(
      // vehFenceId: json['VehFenceId'],
      // vehicleReg: json['VehicleReg'],
      // polygon: json['Polygon'],
      // label: json['Label'],
      vehFenceId: json['VehFenceId'] == null ? null : _toInt(json['VehFenceId']),
      vehicleReg: json['VehicleReg']?.toString() ?? '',
      polygon:    json['Polygon']?.toString()    ?? '',
      label:      json['Label']?.toString()      ?? '',

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'VehFenceId': vehFenceId,
      'VehicleReg': vehicleReg,
      'Polygon': polygon,
      'Label': label
    };
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
