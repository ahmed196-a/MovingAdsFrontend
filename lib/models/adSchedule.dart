class AdScheduleModel {

  int adID;
  String slotName;
  String bits;

  AdScheduleModel({
    required this.adID,
    required this.slotName,
    required this.bits
  });

  Map<String, dynamic> toJson() {
    return {
      "AdID": adID,
      "SlotName": slotName,
      "Bits": bits
    };
  }

}