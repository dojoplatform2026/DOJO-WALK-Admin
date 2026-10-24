import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_identity.dart';

/// Applies live authorization revocation to a stream for an authenticated user.
///
/// The input stream represents that user's live admin document. A missing or
/// unauthorized identity emits null and triggers sign-out. Keeping this
/// transform separate makes the revocation behavior testable without Firebase.
class AdminIdentityRevocationGuard {
  const AdminIdentityRevocationGuard._();

  static Stream<AdminIdentity?> watch(
    Stream<AdminIdentity?> identities, {
    required Future<void> Function() onRevoked,
  }) {
    return identities.asyncMap((identity) async {
      if (identity == null || !identity.canEnterAdmin) {
        await onRevoked();
        return null;
      }
      return identity;
    });
  }
}

/// Fresh auth/data-access boundary for the rebuilt Admin UI.
///
/// No legacy widgets or screens are imported here. The repository checks the
/// same role required by the trusted Firebase callables and Firestore Rules.
class AdminAuthRepository {
  AdminAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<AdminIdentity?> watchAdminIdentity() {
    // Keep the authorization document live. Auth-state changes alone do not
    // notify the UI when an admin is deactivated or their role is changed.
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream<AdminIdentity?>.value(null);

      final documentIdentities = _firestore
          .collection('admin_users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) => _identityFromSnapshot(user, snapshot));

      return AdminIdentityRevocationGuard.watch(
        documentIdentities,
        onRevoked: () async {
          if (_auth.currentUser?.uid == user.uid) {
            await _auth.signOut();
          }
        },
      );
    });
  }

  Future<AdminIdentity> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw StateError('Login could not be completed.');
    }

    try {
      final identity = await _loadAuthorizedIdentity(user);
      if (identity == null) {
        throw StateError(
          'Admin access denied. An active super_admin account is required.',
        );
      }
      return identity;
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  Future<AdminIdentity?> currentIdentity() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final identity = await _loadAuthorizedIdentity(user);
    if (identity == null) {
      await _auth.signOut();
    }
    return identity;
  }

  Future<void> signOut() => _auth.signOut();

  Future<AdminIdentity?> _loadAuthorizedIdentity(User user) async {
    final snapshot = await _firestore
        .collection('admin_users')
        .doc(user.uid)
        .get();
    return _identityFromSnapshot(user, snapshot);
  }

  AdminIdentity? _identityFromSnapshot(
    User user,
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;

    final identity = AdminIdentity(
      uid: user.uid,
      email: user.email,
      role: data['role']?.toString() ?? '',
      isActive: data['isActive'] == true,
      displayName: (data['displayName'] ?? data['name'])?.toString(),
    );

    // Match the existing trusted Functions / Rules policy. UI checks do not
    // replace server-side authorization.
    if (!identity.canEnterAdmin) return null;
    return identity;
  }
}
