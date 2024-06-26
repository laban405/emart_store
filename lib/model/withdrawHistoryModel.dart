import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawHistoryModel {
  String vendorID;

  dynamic amount;

  String note;

  String paymentStatus;

  Timestamp paidDate;

  String id, adminNote,role;

  WithdrawHistoryModel({
    required this.amount,
    required this.vendorID,
    required this.paymentStatus,
    required this.paidDate,
    required this.id,
    required this.note,
    this.adminNote = "",
    this.role = "",
  });

  factory WithdrawHistoryModel.fromJson(Map<String, dynamic> parsedJson) {
    return WithdrawHistoryModel(
      amount: parsedJson['amount'] ?? 0.0,
      id: parsedJson['id'],
      paidDate: parsedJson['paidDate'] ?? '',
      paymentStatus: parsedJson['paymentStatus'] ?? 'Pending',
      vendorID: parsedJson['vendorID'],
      note: parsedJson['note'] ?? "",
      adminNote: parsedJson['adminNote'] ?? "",
      role: parsedJson['role'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'amount': this.amount,
      'id': this.id,
      'paidDate': this.paidDate,
      'paymentStatus': this.paymentStatus,
      'vendorID': this.vendorID,
      'note': this.note,
      'adminNote': this.adminNote,
      'role': this.role,
    };
    return json;
  }
}
