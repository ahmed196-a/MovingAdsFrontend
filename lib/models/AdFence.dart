class AdFence {
  final int? adFenceId;
  final int adId;
  final String polygon;
  final String label;

  AdFence({
    this.adFenceId,
    required this.adId,
    required this.polygon,
    required this.label
  });

  factory AdFence.fromJson(Map<String, dynamic> json) {
    return AdFence(
      // adFenceId: json['AdFenceId'],
      // adId: json['AdId'],
      // polygon: json['Polygon'],
      // label: json['Label'],
      adFenceId: json['AdFenceId'] == null ? null : _toInt(json['AdFenceId']),
      adId:      _toInt(json['AdId']),
      polygon:   json['Polygon'] as String,
      label:     json['Label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AdFenceId': adFenceId,
      'AdId': adId,
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

