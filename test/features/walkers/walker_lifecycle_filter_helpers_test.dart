import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/features/walkers/utils/walker_admin_helpers.dart';

void main() {
  group('POL-004 walker lifecycle filters', () {
    test('Training Required is distinct from application verification', () {
      final walker = <String, dynamic>{
        'status': 'training_required',
        'verificationStatus': 'pending',
        'applicationSubmitted': true,
        'isApproved': false,
        'isActive': false,
      };

      expect(WalkerAdminHelpers.isTrainingRequired(walker), isTrue);
      expect(WalkerAdminHelpers.isApplicationUnderReview(walker), isFalse);
      expect(WalkerAdminHelpers.displayStatus('training_required'),
          'Training Required');
    });

    test('approved inactive walkers appear in inactive lifecycle filter', () {
      final inactive = <String, dynamic>{
        'status': 'approved',
        'verificationStatus': 'verified',
        'isApproved': true,
        'isActive': false,
      };
      final active = <String, dynamic>{
        'status': 'approved',
        'verificationStatus': 'verified',
        'isApproved': true,
        'isActive': true,
      };

      expect(WalkerAdminHelpers.isInactiveOrOffboarded(inactive), isTrue);
      expect(WalkerAdminHelpers.isInactiveOrOffboarded(active), isFalse);
    });

    test('legacy left and canonical offboarded map to offboarding state', () {
      expect(
        WalkerAdminHelpers.isInactiveOrOffboarded({'status': 'left'}),
        isTrue,
      );
      expect(
        WalkerAdminHelpers.isInactiveOrOffboarded({'status': 'offboarded'}),
        isTrue,
      );
      expect(WalkerAdminHelpers.displayStatus('left'), 'Offboarded');
      expect(WalkerAdminHelpers.displayStatus('offboarded'), 'Offboarded');
    });
  });
}
