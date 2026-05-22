class UserModel {
  final String uid;

  final String fullName;

  final String email;

  final String phone;

  final String role;

  final bool isActive;

  final bool isOnline;

  final String assignedArea;

  final String employeeId;

  final String photoUrl;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.isOnline,
    required this.assignedArea,
    required this.employeeId,
    required this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"] ?? "",

      fullName: map["fullName"] ?? "",

      email: map["email"] ?? "",

      phone: map["phone"] ?? "",

      role: map["role"] ?? "user",

      isActive: map["isActive"] ?? true,

      isOnline: map["isOnline"] ?? false,

      assignedArea: map["assignedArea"] ?? "",

      employeeId: map["employeeId"] ?? "",

      photoUrl: map["photoUrl"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,

      "fullName": fullName,

      "email": email,

      "phone": phone,

      "role": role,

      "isActive": isActive,

      "isOnline": isOnline,

      "assignedArea": assignedArea,

      "employeeId": employeeId,

      "photoUrl": photoUrl,
    };
  }
}
