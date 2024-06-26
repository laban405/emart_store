class AdminCommissionModel {
  int? commission;
  bool? enable;
  String? type;

  AdminCommissionModel({this.commission, this.enable, this.type});

  AdminCommissionModel.fromJson(Map<String, dynamic> json) {
    commission = json['commission'];
    enable = json['enable'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['commission'] = this.commission;
    data['enable'] = this.enable;
    data['type'] = this.type;
    return data;
  }
}
