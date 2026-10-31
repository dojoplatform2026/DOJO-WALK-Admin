import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/walker_admin_model.dart';
import '../utils/walker_admin_helpers.dart';
import 'walker_admin_contracts.dart';
import 'walker_admin_transition_policy.dart';

/// Shared Firestore service for DOJO WALK Admin Walker Management.
///
/// Responsibilities:
/// - Read walker data.
/// - Read related booking and audit data.
/// - Validate administrative actions.
/// - Update walker state and write audit logs atomically.
///
/// Firestore Security Rules must independently enforce admin permissions.
class WalkerAdminService {
  WalkerAdminService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _walkers =>
      _firestore.collection('walkers');

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get _auditLogs =>
      _firestore.collection('audit_logs');

  CollectionReference<Map<String, dynamic>> get _adminUsers =>
      _firestore.collection('admin_users');

  // ----------------------------------------------------------
  // READ: WALKERS
  // ----------------------------------------------------------

  /// Streams all walker documents.
  ///
  /// Filtering and search can be performed by the UI.
  Stream<List<WalkerAdminModel>> watchWalkers() {
    return _walkers.snapshots().map((snapshot) {
      return snapshot.docs
          .map(WalkerAdminModel.fromFirestore)
          .toList(growable: false);
    });
  }

  /// Streams one walker's document.
  Stream<WalkerAdminModel?> watchWalker(String uid) {
    return _walkers.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;

      return WalkerAdminModel.fromFirestore(snapshot);
    });
  }

  /// Fetches one walker once.
  Future<WalkerAdminModel?> getWalker(String uid) async {
    final snapshot = await _walkers.doc(uid).get();

    if (!snapshot.exists) return null;

    return WalkerAdminModel.fromFirestore(snapshot);
  }

  // ----------------------------------------------------------
  // READ: BOOKINGS
  // ----------------------------------------------------------

  /// Streams bookings used by the running-walker dashboard.
  ///
  /// The UI must still validate booking status and walkerId.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchBookings() {
    return _bookings.snapshots();
  }

  /// Streams bookings for a particular walker.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchWalkerBookings(
    String walkerId,
  ) {
    return _bookings
        .where('walkerId', isEqualTo: walkerId)
        .snapshots();
  }

  // ----------------------------------------------------------
  // READ: AUDIT HISTORY
  // ----------------------------------------------------------

  /// Streams audit logs associated with a walker.
  ///
  /// Orders on the server before applying the limit, so the stream
  /// consistently returns the newest records first.
  ///
  /// Requires the audit_logs composite index for targetType,
  /// targetId and createdAt (descending).
  Stream<List<Map<String, dynamic>>> watchWalkerAuditLogs(
    String walkerId, {
    int limit = 50,
  }) {
    final safeLimit = limit.clamp(1, 200);

    return _auditLogs
        .where('targetType', isEqualTo: 'walker')
        .where('targetId', isEqualTo: walkerId)
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs.map((doc) {
        return <String, dynamic>{
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      records.sort((a, b) {
        final aDate = WalkerAdminHelpers.toDateTime(
          a['createdAt'],
        );

        final bDate = WalkerAdminHelpers.toDateTime(
          b['createdAt'],
        );

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;

        return bDate.compareTo(aDate);
      });

      return records;
    });
  }

  // ----------------------------------------------------------
  // ADMIN ACTIONS
  // ----------------------------------------------------------

  /// Executes an administrative action.
  ///
  /// Walker state and its audit record are written in the same
  /// Firestore transaction so they cannot be partially committed.
  ///
  /// A reason is required for rejection, suspension and correction.
  Future<void> runAdminAction({
    required String walkerId,
    required WalkerAdminAction action,
    String? reason,
  }) async {
    final admin = _auth.currentUser;

    if (admin == null) {
      throw const WalkerAdminServiceException(
        'Please sign in again before performing this action.',
      );
    }

    final normalizedReason =
        WalkerAdminTransitionPolicy.normalizeReason(action, reason);

    final walkerRef = _walkers.doc(walkerId);
    final adminRef = _adminUsers.doc(admin.uid);
    final auditRef = _auditLogs.doc();

    await _firestore.runTransaction<void>((transaction) async {
      // Read all documents before writing.
      final adminSnapshot = await transaction.get(adminRef);
      final walkerSnapshot = await transaction.get(walkerRef);

      if (!adminSnapshot.exists) {
        throw const WalkerAdminServiceException(
          'Admin access could not be verified.',
        );
      }

      final adminData = adminSnapshot.data();

      if (adminData == null ||
          adminData['isActive'] != true ||
          adminData['role'] != 'super_admin') {
        throw const WalkerAdminServiceException(
          'You do not have permission to perform this action.',
        );
      }

      if (!walkerSnapshot.exists) {
        throw const WalkerAdminServiceException(
          'This walker account no longer exists.',
        );
      }

      final before = walkerSnapshot.data();

      if (before == null) {
        throw const WalkerAdminServiceException(
          'Walker information could not be loaded.',
        );
      }

      final currentStatus =
          WalkerAdminHelpers.normalizeStatus(before['status']);

      final currentVerification = WalkerAdminHelpers.normalizeStatus(
        before['verificationStatus'],
      );

      final currentlyApproved = before['isApproved'] == true;
      final currentlyActive = before['isActive'] == true;

      final changes = _buildChanges(
        action: action,
        status: currentStatus,
        verificationStatus: currentVerification,
        isApproved: currentlyApproved,
        isActive: currentlyActive,
        applicationSubmitted: before['applicationSubmitted'] == true,
      );

      final timestamp = FieldValue.serverTimestamp();

      changes['updatedAt'] = timestamp;
      changes['decisionBy'] = admin.uid;
      changes['decisionAt'] = timestamp;

      if (normalizedReason.isNotEmpty) {
        changes['decisionReason'] = normalizedReason;
      }

      final auditRecord = <String, dynamic>{
        'actorUid': admin.uid,
        'actorRole': 'super_admin',
        'action': WalkerAdminTransitionPolicy.auditActionName(action),
        'targetType': 'walker',
        'targetId': walkerId,
        'beforeStatus': currentStatus,
        'afterStatus': changes['status'],
        'beforeVerificationStatus': currentVerification,
        'afterVerificationStatus': changes['verificationStatus'],
        'beforeIsApproved': currentlyApproved,
        'afterIsApproved': changes['isApproved'],
        'beforeIsActive': currentlyActive,
        'afterIsActive': changes['isActive'],
        'createdAt': timestamp,
      };

      if (normalizedReason.isNotEmpty) {
        auditRecord['reason'] = normalizedReason;
      }

      transaction.update(walkerRef, changes);
      transaction.set(auditRef, auditRecord);
    });
  }

  // ----------------------------------------------------------
  // STATE TRANSITIONS
  // ----------------------------------------------------------

  Map<String, dynamic> _buildChanges({
    required WalkerAdminAction action,
    required String status,
    required String verificationStatus,
    required bool isApproved,
    required bool isActive,
    required bool applicationSubmitted,
  }) {
    return WalkerAdminTransitionPolicy.buildChanges(
      action: action,
      status: status,
      verificationStatus: verificationStatus,
      isApproved: isApproved,
      isActive: isActive,
      applicationSubmitted: applicationSubmitted,
    );
  }

}
