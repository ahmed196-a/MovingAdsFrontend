class SlotDayDTO {
  final String slotName;
  final List<String> days;

  SlotDayDTO({required this.slotName, required this.days});

  factory SlotDayDTO.fromJson(Map<String, dynamic> json) {
    return SlotDayDTO(
      slotName: json['SlotName'] ?? '',
      days: List<String>.from(json['Days'] ?? []),
    );
  }
}

class MatchedDriverGroupedDTO {
  final String vehicleReg;
  final List<SlotDayDTO> slots;

  MatchedDriverGroupedDTO({required this.vehicleReg, required this.slots});

  factory MatchedDriverGroupedDTO.fromJson(Map<String, dynamic> json) {
    return MatchedDriverGroupedDTO(
      vehicleReg: json['VehicleReg'] ?? '',
      slots: (json['Slots'] as List<dynamic>)
          .map((s) => SlotDayDTO.fromJson(s))
          .toList(),
    );
  }
}