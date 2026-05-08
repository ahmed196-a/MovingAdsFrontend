import 'matched_driver_grouped_dto.dart';

class MatchedAgencyDTO {
  final int agencyId;
  final String agencyName;
  final String agencyDescription;
  final String status;
  final String ownerName;
  final String email;
  final int userId;
  final List<MatchedDriverGroupedDTO> vehicles;

  MatchedAgencyDTO({
    required this.agencyId,
    required this.agencyName,
    required this.agencyDescription,
    required this.status,
    required this.ownerName,
    required this.email,
    required this.userId,
    required this.vehicles,
  });

  factory MatchedAgencyDTO.fromJson(Map<String, dynamic> json) {
    return MatchedAgencyDTO(
      agencyId: json['AgencyId'],
      agencyName: json['AgencyName'] ?? '',
      agencyDescription: json['AgencyDescription'] ?? '',
      status: json['Status'] ?? '',
      ownerName: json['OwnerName'] ?? '',
      email: json['Email'] ?? '',
      userId: json['UserId'],
      vehicles: (json['Vehicles'] as List)
          .map((v) => MatchedDriverGroupedDTO.fromJson(v))
          .toList(),
    );
  }
}