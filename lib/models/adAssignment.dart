class AdAssignment {
  final int assignId;
  final int adId;
  final int agencyId;
  final String status;
  final DateTime? assignedAt;

  // Joined fields from backend query
  final String adTitle;

  AdAssignment({
    required this.assignId,
    required this.adId,
    required this.agencyId,
    required this.status,
    this.assignedAt,
    required this.adTitle,
  });

  factory AdAssignment.fromJson(Map<String, dynamic> json) {
    return AdAssignment(
      assignId:     json['AssignId']    ?? 0,
      adId:         json['AdId']        ?? 0,
      agencyId:     json['AgencyId']    ?? 0,
      status:       json['Status']      ?? '',
      assignedAt:   json['AssignedAt'] != null
          ? DateTime.tryParse(json['AssignedAt'])
          : null,
      adTitle:      json['AdTitle']     ?? '',
    );
  }
}