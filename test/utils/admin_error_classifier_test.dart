import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_admin/utils/admin_error_classifier.dart';

void main() {
  test('recognizes common permission-denied error formats', () {
    expect(isPermissionDeniedError(Exception('permission-denied')), isTrue);
    expect(isPermissionDeniedError(Exception('Permission denied by rules')), isTrue);
    expect(isPermissionDeniedError(Exception('Insufficient permissions')), isTrue);
    expect(isPermissionDeniedError(Exception('unauthorized')), isTrue);
  });

  test('does not classify ordinary connectivity errors as permission denied', () {
    expect(isPermissionDeniedError(Exception('SocketException: offline')), isFalse);
    expect(isPermissionDeniedError(null), isFalse);
  });
}
