class Agency {
  final int agencyId;
  final String agencyName;
  final String agencyDescription;
  final String status;
  final String ownerName;
  final String email;
  final int? userId;

  Agency({
    required this.agencyId,
    required this.agencyName,
    required this.agencyDescription,
    required this.status,
    required this.ownerName,
    required this.email,
    this.userId
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      agencyId:          json['AgencyId']          ?? 0,
      agencyName:        json['AgencyName']         ?? '',
      agencyDescription: json['AgencyDescription']  ?? '',
      status:            json['Status']             ?? '',
      ownerName:         json['OwnerName']          ?? '',
      email:             json['Email']              ?? '',
      userId:            json['UserId'] as int?,
    );
  }
}