import 'package:flutter/material.dart';

import '../core/theme/admin_theme.dart';
import '../core/auth/fresh_admin_auth_gate.dart';

class DojoWalkAdminApp extends StatelessWidget {
  const DojoWalkAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DOJO WALK Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.light(),
      home: const FreshAdminAuthGate(),
    );
  }
}
