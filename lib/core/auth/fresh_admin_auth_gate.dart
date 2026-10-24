import 'package:flutter/material.dart';

import '../../core/auth/admin_auth_repository.dart';
import '../../core/auth/admin_identity.dart';
import 'admin_login_screen.dart';
import '../../features/shell/admin_app_shell.dart';

class FreshAdminAuthGate extends StatefulWidget {
  const FreshAdminAuthGate({super.key, this.authRepository});

  /// Optional seam for deterministic widget tests. Production uses the default
  /// Firebase-backed repository when no repository is supplied.
  final AdminAuthRepository? authRepository;

  @override
  State<FreshAdminAuthGate> createState() => _FreshAdminAuthGateState();
}

class _FreshAdminAuthGateState extends State<FreshAdminAuthGate> {
  late final AdminAuthRepository _authRepository;
  late Stream<AdminIdentity?> _identityStream;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AdminAuthRepository();
    _identityStream = _authRepository.watchAdminIdentity();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AdminIdentity?>(
      stream: _identityStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Admin access could not be checked.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(snapshot.error.toString()),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => setState(() {
                          _identityStream = _authRepository.watchAdminIdentity();
                        }),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final identity = snapshot.data;
        if (identity == null) {
          return AdminLoginScreen(authRepository: _authRepository);
        }

        return AdminAppShell(
          identity: identity,
          authRepository: _authRepository,
        );
      },
    );
  }
}
