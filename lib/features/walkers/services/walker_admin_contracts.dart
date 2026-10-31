/// Supported administrative actions for a walker.
enum WalkerAdminAction {
  approve,
  reject,
  suspend,
  reactivate,
  requestCorrection,
}

/// Safe, user-displayable service exception.
class WalkerAdminServiceException implements Exception {
  final String message;

  const WalkerAdminServiceException(this.message);

  @override
  String toString() => message;
}
