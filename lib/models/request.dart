class Request {
  final int? reqID;
  final int requestedBy;
  final int requestedTo;
  final int adId;
  final String vehReg;
  String? status;

  // Optional joined info
  final String? fromUser;
  final String? toUser;
  final String? adTitle;

  Request({
    this.reqID,
    required this.requestedBy,
    required this.requestedTo,
    required this.adId,
    required this.vehReg,
    this.status,
    this.fromUser,
    this.toUser,
    this.adTitle,
  });

  factory Request.fromMap(Map<String, dynamic> json) {
    return Request(
      reqID: json['ReqID'],
      requestedBy: json['RequestedBy'] ?? 0,
      requestedTo: json['RequestedTo'] ?? 0,
      adId: json['AdId'] ?? 0,
      vehReg: json['VehReg'] ?? '',
      status: json['Status'],
      fromUser: json['FromUser'],
      toUser: json['ToUser'],
      adTitle: json['AdTitle'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "ReqID": reqID,
      "RequestedBy": requestedBy,
      "RequestedTo": requestedTo,
      "AdId": adId,
      "VehReg": vehReg,
      "Status": status,
      "FromUser": fromUser,
      "ToUser": toUser,
      "AdTitle": adTitle,
    };
  }
}