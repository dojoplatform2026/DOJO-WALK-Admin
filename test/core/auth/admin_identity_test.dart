import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/core/auth/admin_identity.dart';

void main() {
  group('AdminIdentity.canEnterAdmin', () {
    test('allows an active super_admin', () {
      const identity = AdminIdentity(
        uid: 'admin-1',
        email: 'admin@example.test',
        role: 'super_admin',
        isActive: true,
      );

      expect(identity.canEnterAdmin, isTrue);
    });

    test('denies an inactive super_admin', () {
      const identity = AdminIdentity(
        uid: 'admin-1',
        email: 'admin@example.test',
        role: 'super_admin',
        isActive: false,
      );

      expect(identity.canEnterAdmin, isFalse);
    });

    test('denies an active admin role under the fresh UI policy', () {
      const identity = AdminIdentity(
        uid: 'admin-2',
        email: 'admin@example.test',
        role: 'admin',
        isActive: true,
      );

      expect(identity.canEnterAdmin, isFalse);
    });

    test('denies an unknown role', () {
      const identity = AdminIdentity(
        uid: 'admin-3',
        email: 'admin@example.test',
        role: 'area_manager',
        isActive: true,
      );

      expect(identity.canEnterAdmin, isFalse);
    });
  });
}
