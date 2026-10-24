import 'dart:async';

import 'package:dojo_admin/core/auth/admin_auth_repository.dart';
import 'package:dojo_admin/core/auth/admin_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminIdentityRevocationGuard', () {
    const activeAdmin = AdminIdentity(
      uid: 'admin-1',
      email: 'admin@example.test',
      role: 'super_admin',
      isActive: true,
    );

    test('emits null and signs out when live identity becomes inactive',
        () async {
      final source = StreamController<AdminIdentity?>();
      final emitted = <AdminIdentity?>[];
      var signOutCalls = 0;

      final subscription = AdminIdentityRevocationGuard.watch(
        source.stream,
        onRevoked: () async {
          signOutCalls++;
        },
      ).listen(emitted.add);

      source.add(activeAdmin);
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [activeAdmin]);
      expect(signOutCalls, 0);

      source.add(const AdminIdentity(
        uid: 'admin-1',
        email: 'admin@example.test',
        role: 'super_admin',
        isActive: false,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [activeAdmin, null]);
      expect(signOutCalls, 1);

      await source.close();
      await subscription.cancel();
    });

    test('emits null and signs out when the role is changed', () async {
      final source = StreamController<AdminIdentity?>();
      final emitted = <AdminIdentity?>[];
      var signOutCalls = 0;

      final subscription = AdminIdentityRevocationGuard.watch(
        source.stream,
        onRevoked: () async {
          signOutCalls++;
        },
      ).listen(emitted.add);

      source.add(activeAdmin);
      await Future<void>.delayed(Duration.zero);
      source.add(const AdminIdentity(
        uid: 'admin-1',
        email: 'admin@example.test',
        role: 'admin',
        isActive: true,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [activeAdmin, null]);
      expect(signOutCalls, 1);

      await source.close();
      await subscription.cancel();
    });

    test('emits null and signs out when the admin document is missing',
        () async {
      final source = StreamController<AdminIdentity?>();
      final emitted = <AdminIdentity?>[];
      var signOutCalls = 0;

      final subscription = AdminIdentityRevocationGuard.watch(
        source.stream,
        onRevoked: () async {
          signOutCalls++;
        },
      ).listen(emitted.add);

      source.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(emitted, [null]);
      expect(signOutCalls, 1);

      await source.close();
      await subscription.cancel();
    });
  });
}
