

import 'package:emartstore/model/User.dart';

class AddressModel {
  String? id;
  String? address;
  String? addressAs;
  String? landmark;
  String? locality;
  UserLocation? location;
  bool? isDefault;

  AddressModel({this.address, this.landmark, this.locality, this.location, this.isDefault, this.addressAs, this.id});

  AddressModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    address = json['address'];
    landmark = json['landmark'];
    locality = json['locality'];
    isDefault = json['isDefault'];
    addressAs = json['addressAs'];
    location = json['location'] == null ? null : UserLocation.fromJson(json['location']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['address'] = this.address;
    data['landmark'] = this.landmark;
    data['locality'] = this.locality;
    data['isDefault'] = this.isDefault;
    data['addressAs'] = this.addressAs;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
    }
    return data;
  }

  String getFullAddress() {
    print(address);
    print(locality);
    print(landmark);
    return '${address == null || address!.isEmpty ? "" : address} $locality ${landmark == null || landmark!.isEmpty ? "" : landmark.toString()}';
  }
}
