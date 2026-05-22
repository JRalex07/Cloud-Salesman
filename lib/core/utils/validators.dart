class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter email";
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter password";
    }

    if (value.length < 6) {
      return "Password too short";
    }

    return null;
  }

  static String? requiredField(String? value) {
    if (value == null || value.isEmpty) {
      return "Required field";
    }

    return null;
  }
}
