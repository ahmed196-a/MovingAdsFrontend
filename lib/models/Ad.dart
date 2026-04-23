class Ad {
  final int adId;
  final String adTitle;
  final String mediaType;
  final String mediaName;
  final String mediaPath;
  final int userId;
  final String userName;
  final String userRole;
  final String status; // active | paused | completed
  final DateTime StartingDate;
  final DateTime EndingDate;
  final String Category;
  Ad({
    required this.adId,
    required this.adTitle,
    required this.mediaType,
    required this.mediaName,
    required this.mediaPath,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.status,
    required this.StartingDate,
    required this.EndingDate,
    required this.Category
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      adId: json['AdId'],
      adTitle: json['AdTitle'],
      mediaType: json['MediaType'],
      mediaName: json['MediaName'], // spelling kept same as backend
      mediaPath: json['MediaPath'],
      userId: json['UserId'],
      userName: json['UserName'],
      userRole: json['UserRole'],
      status: json['Status'],

        StartingDate: json['StartingDate'] != null
            ? DateTime.parse(json['StartingDate'])
            : DateTime.now(),   // 👈 fallback

        EndingDate: json['EndingDate'] != null
            ? DateTime.parse(json['EndingDate'])
            : DateTime.now(),
      Category: json['Category']
    );
  }
}
