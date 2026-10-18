abstract interface class NotificationPermissionService {
  /// Shows the OS prompt. Resolves to whether notifications are allowed.
  Future<bool> request();
}
