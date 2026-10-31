import 'dart:convert';
import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dojo_admin/features/walkers/services/walker_admin_contracts.dart';
import 'package:dojo_admin/features/walkers/services/walker_admin_service.dart';

const projectId = String.fromEnvironment(
  'DOJO_EMULATOR_PROJECT_ID',
  defaultValue: 'demo-dojo-admin-integration',
);

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Initialize the Android default app once for the whole integration suite.
  // The platform implementation does not support deleting the default app.
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'fake-api-key',
      appId: '1:123456789:android:dojo-walker-default',
      messagingSenderId: '123456789',
      projectId: projectId,
    ),
  );

  testWidgets(
    'real WalkerAdminService rejects an unauthorised emulator user without writes',
    (tester) async {
      final app = await Firebase.initializeApp(
        name: 'dojo-walker-emulator-integration',
        options: FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: '1:123456789:web:dojo-walker-integration',
          messagingSenderId: '123456789',
          projectId: projectId,
          authDomain: '$projectId.firebaseapp.com',
        ),
      );
      // Keep named Firebase apps alive until the integration process exits.
      // Deleting an app between testWidgets cases leaves FirebaseAuth's Android
      // platform channel holding a deleted-app handle for the next test.

      final auth = FirebaseAuth.instanceFor(app: app);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      // Android Emulator reaches host-machine services through 10.0.2.2;
      // loopback inside the emulator points back to the Android guest itself.
      final emulatorHost = io.Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      await auth.useAuthEmulator(emulatorHost, 9099);
      firestore.useFirestoreEmulator(emulatorHost, 8080);

      final credential = await auth.createUserWithEmailAndPassword(
        email: 'unauthorised-${DateTime.now().microsecondsSinceEpoch}@dojo.test',
        password: 'Dojo-Emulator-Test-2026!',
      );
      final uid = credential.user!.uid;

      final service = WalkerAdminService(firestore: firestore, auth: auth);
      await expectLater(
        service.runAdminAction(
          walkerId: uid,
          action: WalkerAdminAction.approve,
        ),
        throwsA(isA<WalkerAdminServiceException>()),
      );

      // The authenticated user may read their own walker path. The service
      // must stop at the missing admin record and leave that path untouched.
      final walker = await firestore.collection('walkers').doc(uid).get();
      expect(walker.exists, isFalse);
      expect(credential.user!.uid, uid);
    },
  );

  testWidgets(
    'real WalkerAdminService approves an emulator fixture and writes its audit record',
    (tester) async {
      final app = await Firebase.initializeApp(
        name: 'dojo-walker-success-integration',
        options: FirebaseOptions(
          apiKey: 'fake-api-key',
          appId: '1:123456789:web:dojo-walker-success',
          messagingSenderId: '123456789',
          projectId: projectId,
          authDomain: '$projectId.firebaseapp.com',
        ),
      );
      // Keep named Firebase apps alive until the integration process exits.
      // Deleting an app between testWidgets cases leaves FirebaseAuth's Android
      // platform channel holding a deleted-app handle for the next test.

      final auth = FirebaseAuth.instanceFor(app: app);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      final emulatorHost = io.Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      await auth.useAuthEmulator(emulatorHost, 9099);
      firestore.useFirestoreEmulator(emulatorHost, 8080);

      final credential = await auth.createUserWithEmailAndPassword(
        email: 'super-admin-fixture-${DateTime.now().microsecondsSinceEpoch}@dojo.test',
        password: 'Dojo-Emulator-Test-2026!',
      );
      final uid = credential.user!.uid;

      // The emulator's documented owner token bypasses rules only on the
      // local Firestore Emulator. Never use this fixture helper with a
      // production project or production endpoint.
      final fixtureClient = io.HttpClient();
      addTearDown(fixtureClient.close);
      final baseUri = Uri.parse(
        'http://$emulatorHost:8080/v1/projects/$projectId/databases/(default)/documents',
      );

      Future<void> seedDocument(
        String collection,
        Map<String, Object> fields,
      ) async {
        final uri = baseUri.replace(path: '${baseUri.path}/$collection/$uid');
        final request = await fixtureClient.patchUrl(uri);
        request.headers.set(io.HttpHeaders.authorizationHeader, 'Bearer owner');
        request.headers.contentType = io.ContentType.json;
        request.write(jsonEncode({
          'fields': fields,
        }));
        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();
        expect(
          response.statusCode,
          anyOf(io.HttpStatus.ok, io.HttpStatus.created),
          reason: 'Emulator fixture seed failed: $body',
        );
      }

      print('[walker-admin-it] seeding emulator admin fixture');
      await seedDocument('admin_users', {
        'role': {'stringValue': 'super_admin'},
        'isActive': {'booleanValue': true},
      });
      print('[walker-admin-it] seeding emulator walker fixture');
      await seedDocument('walkers', {
        'userId': {'stringValue': uid},
        'fullName': {'stringValue': 'Emulator Test Walker'},
        'phone': {'stringValue': '+910000000000'},
        'status': {'stringValue': 'under_review'},
        'isActive': {'booleanValue': false},
        'isApproved': {'booleanValue': false},
        'verificationStatus': {'stringValue': 'pending'},
        'applicationSubmitted': {'booleanValue': true},
        'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
        'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      });

      print('[walker-admin-it] fixtures seeded; invoking real service transaction');
      final service = WalkerAdminService(firestore: firestore, auth: auth);
      await service.runAdminAction(
        walkerId: uid,
        action: WalkerAdminAction.approve,
      ).timeout(const Duration(seconds: 60));
      print('[walker-admin-it] service transaction returned; reading walker');

      final walker = await firestore.collection('walkers').doc(uid).get();
      expect(walker.data()?['status'], 'approved');
      expect(walker.data()?['verificationStatus'], 'verified');
      expect(walker.data()?['isApproved'], isTrue);
      expect(walker.data()?['isActive'], isTrue);
      expect(walker.data()?['decisionBy'], uid);

      print('[walker-admin-it] walker state verified; querying audit log');
      final audit = await firestore
          .collection('audit_logs')
          .where('targetType', isEqualTo: 'walker')
          .where('targetId', isEqualTo: uid)
          .get()
          .timeout(const Duration(seconds: 30));
      print('[walker-admin-it] audit query returned ${audit.docs.length} records');
      expect(audit.docs, hasLength(1));
      expect(audit.docs.single.data()['actorUid'], uid);
      expect(audit.docs.single.data()['actorRole'], 'super_admin');
      expect(audit.docs.single.data()['action'], 'walker_approved');
      expect(audit.docs.single.data()['afterStatus'], 'approved');
      expect(audit.docs.single.data()['afterVerificationStatus'], 'verified');
      expect(audit.docs.single.data()['afterIsApproved'], isTrue);
      expect(audit.docs.single.data()['afterIsActive'], isTrue);
    },
  );

}
