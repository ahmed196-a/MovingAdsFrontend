class BillingRate {
  final int rateId;
  final int adId;
  final String rateType; // per_km | per_minute | both
  final double ratePerKm;
  final double ratePerMin;

  BillingRate({
    required this.rateId,
    required this.adId,
    required this.rateType,
    required this.ratePerKm,
    required this.ratePerMin,
  });

  factory BillingRate.fromJson(Map<String, dynamic> json) {
    return BillingRate(
      rateId:     json['RateId']     ?? 0,
      adId:       json['AdId']       ?? 0,
      rateType:   json['RateType']   ?? 'per_km',
      ratePerKm:  (json['RatePerKm']  ?? 0).toDouble(),
      ratePerMin: (json['RatePerMin'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AdId':       adId,
      'RateType':   rateType,
      'RatePerKm':  ratePerKm,
      'RatePerMin': ratePerMin,
    };
  }
}


