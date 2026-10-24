/// Authenticated identity allowed to enter the fresh Admin application.
///
/// This is a UI access check only. Firestore Rules and callable Functions must
/// continue to enforce authorization independently.
class AdminIdentity {
  const AdminIdentity({
    required this.uid,
    required this.email,
    required this.role,
    required this.isActive,
    this.displayName,
  });

  final String uid;
  final String? email;
  final String role;
  final bool isActive;
  final String? displayName;

  bool get canEnterAdmin => isActive && role == 'super_admin';
}
