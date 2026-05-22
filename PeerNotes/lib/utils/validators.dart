class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a valid email address';
    }
    // Strict email regex: requires user, @, domain, and TLD with at least 3 chars
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{3,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]')) ||
        !value.contains(RegExp(r'[a-z]')) ||
        !value.contains(RegExp(r'[0-9]'))) {
      return 'Include uppercase, lowercase, and number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty || value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }
}
