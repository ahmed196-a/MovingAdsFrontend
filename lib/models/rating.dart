class Rating{
  final int ratedBy;     // advertiser/user who rates
  final int ratedTo;     // driverId
  final double ratePoints; // 1..5
  final int adId;        // your API checks Ad.Status by AdId
  final int? assignId;   // optional (your DB schema has AssignId)

  Rating({
    required this.ratedBy,
    required this.ratedTo,
    required this.ratePoints,
    required this.adId,
    this.assignId,
  });

  Map<String, dynamic> toJson() {
    return {
      "RatedBy": ratedBy,
      "RatedTo": ratedTo,
      "RatePoints": ratePoints,
      "AdId": adId,
      if (assignId != null) "AssignId": assignId,
    };
  }
}