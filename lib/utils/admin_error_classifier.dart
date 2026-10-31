/// Classifies common authorization failures for user-facing Admin UI states.
bool isPermissionDeniedError(Object? error) {
  if (error == null) return false;
  final message = error.toString().toLowerCase();
  return message.contains('permission-denied') ||
      message.contains('permission denied') ||
      message.contains('insufficient permission') ||
      message.contains('unauthorized');
}
