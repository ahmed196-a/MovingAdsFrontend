class AdBillingSummary {
  final int adId;
  final int totalDays;
  final double totalDistanceKm;
  final double totalTimeMinutes;
  final double totalAmountDue;
  final double totalPaid;
  final double totalUnpaid;

  AdBillingSummary({
    required this.adId,
    required this.totalDays,
    required this.totalDistanceKm,
    required this.totalTimeMinutes,
    required this.totalAmountDue,
    required this.totalPaid,
    required this.totalUnpaid,
  });

  factory AdBillingSummary.fromJson(Map<String, dynamic> json) {
    return AdBillingSummary(
      adId:             json['AdId']             ?? 0,
      totalDays:        json['TotalDays']        ?? 0,
      totalDistanceKm:  (json['TotalDistanceKm']  ?? 0).toDouble(),
      totalTimeMinutes: (json['TotalTimeMinutes'] ?? 0).toDouble(),
      totalAmountDue:   (json['TotalAmountDue']   ?? 0).toDouble(),
      totalPaid:        (json['TotalPaid']        ?? 0).toDouble(),
      totalUnpaid:      (json['TotalUnpaid']      ?? 0).toDouble(),
    );
  }
}
