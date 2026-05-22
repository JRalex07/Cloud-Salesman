class AttendanceModel {
  final String id;

  final String salesmanId;

  final DateTime startDuty;

  final DateTime? endDuty;

  final bool active;

  AttendanceModel({
    required this.id,
    required this.salesmanId,
    required this.startDuty,
    required this.endDuty,
    required this.active,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,

      salesmanId: map["salesmanId"] ?? "",

      startDuty: DateTime.parse(map["startDuty"]),

      endDuty: map["endDuty"] != null ? DateTime.parse(map["endDuty"]) : null,

      active: map["active"] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "salesmanId": salesmanId,

      "startDuty": startDuty.toIso8601String(),

      "endDuty": endDuty?.toIso8601String(),

      "active": active,
    };
  }
}
