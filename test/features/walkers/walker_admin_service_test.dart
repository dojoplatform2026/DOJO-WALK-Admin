import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dojo_admin/features/walkers/services/walker_admin_contracts.dart';
import 'package:dojo_admin/features/walkers/services/walker_admin_service.dart';

void main() {
  const adminUid = 'admin-1';
  const walkerUid = 'walker-1';

  late FakeFirebaseFirestore firestore;

  MockFirebaseAuth auth({
    required bool signedIn,
    String uid = adminUid,
  }) {
    return MockFirebaseAuth(
      signedIn: signedIn,
      mockUser: MockUser(uid: uid),
    );
  }

  Future<void> seedAdmin({
    bool isActive = true,
    String role = 'super_admin',
  }) async {
    await firestore.collection('admin_users').doc(adminUid).set({
      'isActive': isActive,
      'role': role,
    });
  }

  Future<void> seedSubmittedWalker() async {
    await firestore.collection('walkers').doc(walkerUid).set({
      'userId': walkerUid,
      'fullName': 'Test Walker',
      'status': 'under_review',
      'verificationStatus': 'pending',
      'isApproved': false,
      'isActive': false,
      'applicationSubmitted': true,
    });
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('WalkerAdminService.runAdminAction', () {
    test('approves walker and persists matching audit event', () async {
      await seedAdmin();
      await seedSubmittedWalker();

      final service = WalkerAdminService(
        firestore: firestore,
        auth: auth(signedIn: true),
      );

      await service.runAdminAction(
        walkerId: walkerUid,
        action: WalkerAdminAction.approve,
      );

      final walker = await firestore.collection('walkers').doc(walkerUid).get();
      expect(walker.data(), containsPair('status', 'approved'));
      expect(walker.data(), containsPair('verificationStatus', 'verified'));
      expect(walker.data(), containsPair('isApproved', true));
      expect(walker.data(), containsPair('isActive', true));
      expect(walker.data(), containsPair('decisionBy', adminUid));

      final audit = await firestore
          .collection('audit_logs')
          .where('targetId', isEqualTo: walkerUid)
          .get();
      expect(audit.docs, hasLength(1));
      expect(audit.docs.single.data(), containsPair('actorUid', adminUid));
      expect(audit.docs.single.data(),
          containsPair('action', 'walker_approved'));
      expect(audit.docs.single.data(), containsPair('targetType', 'walker'));
      expect(audit.docs.single.data(), containsPair('afterStatus', 'approved'));
    });

    test('rejects action when no admin is signed in', () async {
      final service = WalkerAdminService(
        firestore: firestore,
        auth: auth(signedIn: false),
      );

      await expectLater(
        service.runAdminAction(
          walkerId: walkerUid,
          action: WalkerAdminAction.approve,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );
      expect((await firestore.collection('walkers').get()).docs, isEmpty);
      expect((await firestore.collection('audit_logs').get()).docs, isEmpty);
    });

    test('denies an inactive admin without writing either document', () async {
      await seedAdmin(isActive: false);
      await seedSubmittedWalker();

      final service = WalkerAdminService(
        firestore: firestore,
        auth: auth(signedIn: true),
      );

      await expectLater(
        service.runAdminAction(
          walkerId: walkerUid,
          action: WalkerAdminAction.approve,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );

      final walker = await firestore.collection('walkers').doc(walkerUid).get();
      expect(walker.data(), containsPair('status', 'under_review'));
      expect((await firestore.collection('audit_logs').get()).docs, isEmpty);
    });

    test('denies an active non-super-admin without writing', () async {
      await seedAdmin(role: 'support');
      await seedSubmittedWalker();

      final service = WalkerAdminService(
        firestore: firestore,
        auth: auth(signedIn: true),
      );

      await expectLater(
        service.runAdminAction(
          walkerId: walkerUid,
          action: WalkerAdminAction.approve,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );

      final walker = await firestore.collection('walkers').doc(walkerUid).get();
      expect(walker.data(), containsPair('status', 'under_review'));
      expect((await firestore.collection('audit_logs').get()).docs, isEmpty);
    });

    test('missing walker is rejected without creating an audit event', () async {
      await seedAdmin();
      final service = WalkerAdminService(
        firestore: firestore,
        auth: auth(signedIn: true),
      );

      await expectLater(
        service.runAdminAction(
          walkerId: walkerUid,
          action: WalkerAdminAction.approve,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );

      expect((await firestore.collection('audit_logs').get()).docs, isEmpty);
    });

    test('invalid lifecycle transition writes nothing', () async {
      await seedAdmin();
      await seedSubmittedWalker();
      final service = WalkerAdminService(
        firestore: firestore,
        auth: auth(signedIn: true),
      );

      await expectLater(
        service.runAdminAction(
          walkerId: walkerUid,
          action: WalkerAdminAction.reactivate,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );

      final walker = await firestore.collection('walkers').doc(walkerUid).get();
      expect(walker.data(), containsPair('status', 'under_review'));
      expect((await firestore.collection('audit_logs').get()).docs, isEmpty);
    });

    test('reject requires a reason before transaction begins', () async {
      await seedAdmin();
      await seedSubmittedWalker();
      final service = WalkerAdminService(
        firestore: firestore,
        auth: auth(signedIn: true),
      );

      await expectLater(
        service.runAdminAction(
          walkerId: walkerUid,
          action: WalkerAdminAction.reject,
          reason: '  ',
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );

      final walker = await firestore.collection('walkers').doc(walkerUid).get();
      expect(walker.data(), containsPair('status', 'under_review'));
      expect((await firestore.collection('audit_logs').get()).docs, isEmpty);
    });

    test('stores normalized reason on walker and audit record', () async {
      await seedAdmin();
      await seedSubmittedWalker();
      final service = WalkerAdminService(
        firestore: firestore,
        auth: auth(signedIn: true),
      );

      await service.runAdminAction(
        walkerId: walkerUid,
        action: WalkerAdminAction.reject,
        reason: '  KYC verification failed.  ',
      );

      final walker = await firestore.collection('walkers').doc(walkerUid).get();
      expect(walker.data(), containsPair('decisionReason', 'KYC verification failed.'));

      final audit = await firestore
          .collection('audit_logs')
          .where('targetId', isEqualTo: walkerUid)
          .get();
      expect(audit.docs.single.data(),
          containsPair('reason', 'KYC verification failed.'));
      expect(audit.docs.single.data(),
          containsPair('action', 'walker_rejected'));
    });
  });
}
