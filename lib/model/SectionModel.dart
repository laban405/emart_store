import 'package:emartstore/model/admin_commission_model.dart';

class SectionModel {
  String? referralAmount;
  String? serviceType;
  String? color;
  String? name;
  String? sectionImage;
  String? id;
  bool? isActive;
  bool? dineInActive;
  String? serviceTypeFlag;
  String? delivery_charge;
  int? nearByRadius;
  AdminCommissionModel? adminCommision;

  SectionModel(
      {this.referralAmount,
        this.serviceType,
        this.color,
        this.name,
        this.sectionImage,
        this.id,
        this.isActive,
        this.adminCommision,
        this.dineInActive,
        this.delivery_charge,
        this.nearByRadius,
        this.serviceTypeFlag});

  SectionModel.fromJson(Map<String, dynamic> json) {
    referralAmount = json['referralAmount'] ?? '';
    serviceType = json['serviceType'] ?? '';
    color = json['color'];
    name = json['name'];
    sectionImage = json['sectionImage'];
    id = json['id'];
    adminCommision = json.containsKey('adminCommision') ? AdminCommissionModel.fromJson(json['adminCommision']) : null;
    isActive = json['isActive'];
    dineInActive = json['dine_in_active'] ?? false;
    serviceTypeFlag = json['serviceTypeFlag'] ?? '';
    delivery_charge = json['delivery_charge'] ?? '';
    nearByRadius = json['nearByRadius'] ?? 50000;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['referralAmount'] = referralAmount;
    data['serviceType'] = serviceType;
    data['color'] = color;
    data['name'] = name;
    data['sectionImage'] = sectionImage;
    if (adminCommision != null) {
      data['adminCommision'] = adminCommision!.toJson();
    }
    data['id'] = id;
    data['isActive'] = isActive;
    data['dine_in_active'] = dineInActive;
    data['serviceTypeFlag'] = serviceTypeFlag;
    data['delivery_charge'] = delivery_charge;
    data['nearByRadius'] = nearByRadius;
    return data;
  }
}