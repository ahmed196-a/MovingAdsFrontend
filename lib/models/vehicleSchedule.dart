class VehicleScheduleModel {

  String vehReg;
  String slotName;
  String bits;

  VehicleScheduleModel({
    required this.vehReg,
    required this.slotName,
    required this.bits
  });

  Map<String, dynamic> toJson() {
    return {
      "VehReg": vehReg,
      "SlotName": slotName,
      "Bits": bits
    };
  }

}