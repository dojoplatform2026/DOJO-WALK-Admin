import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/walkers/services/walker_admin_contracts.dart';
import 'package:dojo_admin/features/walkers/services/walker_admin_transition_policy.dart';

void main() {
  group('WalkerAdminTransitionPolicy metadata', () {
    test('requires a reason only for reject suspend and correction', () {
      expect(
        WalkerAdminAction.values
            .where(WalkerAdminTransitionPolicy.requiresReason)
            .toSet(),
        {
          WalkerAdminAction.reject,
          WalkerAdminAction.suspend,
          WalkerAdminAction.requestCorrection,
        },
      );
      expect(
        WalkerAdminAction.values
            .where((action) =>
                !WalkerAdminTransitionPolicy.requiresReason(action))
            .toSet(),
        {WalkerAdminAction.approve, WalkerAdminAction.reactivate},
      );
    });

    test('normalizes reasons and enforces required and maximum length', () {
      expect(
        WalkerAdminTransitionPolicy.normalizeReason(
          WalkerAdminAction.approve,
          '  reviewed  ',
        ),
        'reviewed',
      );
      expect(
        WalkerAdminTransitionPolicy.normalizeReason(
          WalkerAdminAction.approve,
          null,
        ),
        '',
      );
      for (final action in [
        WalkerAdminAction.reject,
        WalkerAdminAction.suspend,
        WalkerAdminAction.requestCorrection,
      ]) {
        expect(
          () => WalkerAdminTransitionPolicy.normalizeReason(action, '  '),
          throwsA(isA<WalkerAdminServiceException>()),
        );
      }
      expect(
        WalkerAdminTransitionPolicy.normalizeReason(
          WalkerAdminAction.reject,
          List.filled(1000, 'r').join(),
        ),
        hasLength(1000),
      );
      expect(
        () => WalkerAdminTransitionPolicy.normalizeReason(
          WalkerAdminAction.reject,
          List.filled(1001, 'r').join(),
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );
    });

    test('maps every action to a stable audit event name', () {
      expect(
        {
          for (final action in WalkerAdminAction.values)
            action: WalkerAdminTransitionPolicy.auditActionName(action),
        },
        {
          WalkerAdminAction.approve: 'walker_approved',
          WalkerAdminAction.reject: 'walker_rejected',
          WalkerAdminAction.suspend: 'walker_suspended',
          WalkerAdminAction.reactivate: 'walker_reactivated',
          WalkerAdminAction.requestCorrection:
              'walker_correction_requested',
        },
      );
    });
  });

  group('WalkerAdminTransitionPolicy', () {
    test('approves a submitted, reviewable application', () {
      expect(
        WalkerAdminTransitionPolicy.buildChanges(
          action: WalkerAdminAction.approve,
          status: 'under_review',
          verificationStatus: 'pending',
          isApproved: false,
          isActive: false,
          applicationSubmitted: true,
        ),
        {
          'status': 'approved',
          'verificationStatus': 'verified',
          'isApproved': true,
          'isActive': true,
        },
      );
    });

    test('rejects approval for unsubmitted or correction-required records', () {
      for (final fixture in [
        ('under_review', 'pending', false),
        ('correction_required', 'correction_required', true),
        ('rejected', 'rejected', true),
        ('suspended', 'verified', true),
      ]) {
        expect(
          () => WalkerAdminTransitionPolicy.buildChanges(
            action: WalkerAdminAction.approve,
            status: fixture.$1,
            verificationStatus: fixture.$2,
            isApproved: false,
            isActive: false,
            applicationSubmitted: fixture.$3,
          ),
          throwsA(isA<WalkerAdminServiceException>()),
        );
      }
    });

    test('rejects only a submitted, unapproved, non-verified application', () {
      expect(
        WalkerAdminTransitionPolicy.buildChanges(
          action: WalkerAdminAction.reject,
          status: 'under_review',
          verificationStatus: 'pending',
          isApproved: false,
          isActive: false,
          applicationSubmitted: true,
        )['status'],
        'rejected',
      );
      expect(
        () => WalkerAdminTransitionPolicy.buildChanges(
          action: WalkerAdminAction.reject,
          status: 'approved',
          verificationStatus: 'verified',
          isApproved: true,
          isActive: true,
          applicationSubmitted: true,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );
    });

    test('suspends only an active approved verified walker', () {
      expect(
        WalkerAdminTransitionPolicy.buildChanges(
          action: WalkerAdminAction.suspend,
          status: 'approved',
          verificationStatus: 'verified',
          isApproved: true,
          isActive: true,
          applicationSubmitted: true,
        ),
        {
          'status': 'suspended',
          'verificationStatus': 'verified',
          'isApproved': true,
          'isActive': false,
        },
      );
      expect(
        () => WalkerAdminTransitionPolicy.buildChanges(
          action: WalkerAdminAction.suspend,
          status: 'approved',
          verificationStatus: 'verified',
          isApproved: true,
          isActive: false,
          applicationSubmitted: true,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );
    });

    test('reactivates only a suspended verified approved walker', () {
      expect(
        WalkerAdminTransitionPolicy.buildChanges(
          action: WalkerAdminAction.reactivate,
          status: 'suspended',
          verificationStatus: 'verified',
          isApproved: true,
          isActive: false,
          applicationSubmitted: true,
        )['isActive'],
        isTrue,
      );
      expect(
        () => WalkerAdminTransitionPolicy.buildChanges(
          action: WalkerAdminAction.reactivate,
          status: 'inactive',
          verificationStatus: 'verified',
          isApproved: true,
          isActive: false,
          applicationSubmitted: true,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );
    });

    test('requests correction only before verification and approval', () {
      expect(
        WalkerAdminTransitionPolicy.buildChanges(
          action: WalkerAdminAction.requestCorrection,
          status: 'under_review',
          verificationStatus: 'pending',
          isApproved: false,
          isActive: false,
          applicationSubmitted: true,
        )['status'],
        'correction_required',
      );
      expect(
        () => WalkerAdminTransitionPolicy.buildChanges(
          action: WalkerAdminAction.requestCorrection,
          status: 'approved',
          verificationStatus: 'verified',
          isApproved: true,
          isActive: true,
          applicationSubmitted: true,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );
    });

    test('does not permit terminal states to be re-approved', () {
      for (final status in ['rejected', 'suspended', 'inactive', 'left']) {
        expect(
          () => WalkerAdminTransitionPolicy.buildChanges(
            action: WalkerAdminAction.approve,
            status: status,
            verificationStatus: 'pending',
            isApproved: false,
            isActive: false,
            applicationSubmitted: true,
          ),
          throwsA(isA<WalkerAdminServiceException>()),
        );
      }
    });
  });
}
