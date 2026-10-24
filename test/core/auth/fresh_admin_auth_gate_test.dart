import 'dart:collection';

import 'package:dojo_admin/core/auth/admin_auth_repository.dart';
import 'package:dojo_admin/core/auth/admin_identity.dart';
import 'package:dojo_admin/core/auth/fresh_admin_auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminAuthRepository implements AdminAuthRepository {
  _FakeAdminAuthRepository(Iterable<Stream<AdminIdentity?>> streams)
      : _streams = Queue.of(streams);

  final Queue<Stream<AdminIdentity?>> _streams;
  int watchCalls = 0;

  @override
  Stream<AdminIdentity?> watchAdminIdentity() {
    watchCalls++;
    if (_streams.isEmpty) return Stream<AdminIdentity?>.value(null);
    return _streams.removeFirst();
  }

  @override
  Future<AdminIdentity> signIn({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<AdminIdentity?> currentIdentity() async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  group('FreshAdminAuthGate', () {
    testWidgets('shows a retryable error when auth status cannot be checked',
        (tester) async {
      final repository = _FakeAdminAuthRepository([
        Stream<AdminIdentity?>.error(StateError('temporary Firestore error')),
        Stream<AdminIdentity?>.value(null),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: FreshAdminAuthGate(authRepository: repository)),
      );
      await tester.pump();

      expect(find.text('Admin access could not be checked.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Sign in securely'), findsNothing);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();

      expect(repository.watchCalls, 2);
      expect(find.text('Sign in securely'), findsOneWidget);
      expect(find.text('Admin access could not be checked.'), findsNothing);
    });

    testWidgets('does not show the Admin shell when identity is absent',
        (tester) async {
      final repository = _FakeAdminAuthRepository([
        Stream<AdminIdentity?>.value(null),
      ]);

      await tester.pumpWidget(
        MaterialApp(home: FreshAdminAuthGate(authRepository: repository)),
      );
      await tester.pump();

      expect(find.text('Sign in securely'), findsOneWidget);
      expect(find.text('Admin access could not be checked.'), findsNothing);
    });
  });
}
