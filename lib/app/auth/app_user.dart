class AppUser {
  const AppUser({required this.id, this.email, this.displayName});

  final String id;
  final String? email;
  final String? displayName;

  String get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final address = email?.trim();
    if (address != null && address.isNotEmpty) return address;
    return id;
  }
}
