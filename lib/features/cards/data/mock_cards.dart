import 'package:kazzi_credit/features/cards/domain/card_network.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';

// Demo data until a real backend exists. Numbers are Luhn-valid test
// values, not real accounts.

/// Placeholder holder name; replaced with the user's name at onboarding.
const demoHolder = 'Juan Dela Cruz';

List<PaymentCard> mockCards(DateTime now, {String holder = demoHolder}) => [
  PaymentCard(
    id: 'everyday',
    nickname: 'Everyday',
    holder: holder,
    last4: '4821',
    network: CardNetwork.visa,
    expiryMonth: 9,
    expiryYear: 2029,
    themeId: 'midnight',
    creditLimit: 80000,
    balance: 24350.75,
    statementBalance: 18920.40,
    minimumDue: 950,
    dueDate: now.add(const Duration(days: 6)),
  ),
  PaymentCard(
    id: 'travel',
    nickname: 'Travel',
    holder: holder,
    last4: '9012',
    network: CardNetwork.mastercard,
    expiryMonth: 3,
    expiryYear: 2028,
    themeId: 'ocean',
    creditLimit: 250000,
    balance: 92410.20,
    statementBalance: 61300,
    minimumDue: 3065,
    dueDate: now.add(const Duration(days: 18)),
  ),
  PaymentCard(
    id: 'rewards',
    nickname: 'Rewards',
    holder: holder,
    last4: '3456',
    network: CardNetwork.amex,
    expiryMonth: 11,
    expiryYear: 2030,
    themeId: 'lime',
    creditLimit: 120000,
    balance: 12840.50,
    statementBalance: 9210,
    minimumDue: 500,
    dueDate: now.add(const Duration(days: 23)),
  ),
];

const mockCardSecrets = {
  'everyday': CardSecrets(number: '4539140000054821', cvv: '417'),
  'travel': CardSecrets(number: '5522040000019012', cvv: '208'),
  'rewards': CardSecrets(number: '378282000013456', cvv: '6631'),
};
