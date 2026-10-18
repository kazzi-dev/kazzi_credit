abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const profileSetup = '/onboarding/profile';
  static const pinSetup = '/onboarding/pin';
  static const finishSetup = '/onboarding/finish';
  static const lock = '/lock';

  // Bottom-nav tabs.
  static const home = '/home';
  static const addCard = '/home/add-card';
  static const transactions = '/transactions';
  static const insights = '/insights';
  static const profile = '/profile';

  static const designSystem = '/profile/design-system';

  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';

  /// Opens the wallet with this card centered.
  static String cardInWallet(String cardId) =>
      Uri(path: home, queryParameters: {'card': cardId}).toString();

  static const transactionPattern = '/transaction/:id';
  static String transactionDetail(String id, {String? from}) => Uri(
    path: '/transaction/$id',
    queryParameters: from == null ? null : {'from': from},
  ).toString();
}
