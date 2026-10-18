import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kazzi_credit/core/router/routes.dart';
import 'package:kazzi_credit/core/theme/app_tokens.dart';
import 'package:kazzi_credit/core/theme/theme_extensions.dart';
import 'package:kazzi_credit/core/widgets/app_toast.dart';
import 'package:kazzi_credit/core/widgets/empty_state.dart';
import 'package:kazzi_credit/core/widgets/section_header.dart';
import 'package:kazzi_credit/features/auth/presentation/reauthenticate.dart';
import 'package:kazzi_credit/features/cards/application/card_reveal_controller.dart';
import 'package:kazzi_credit/features/cards/application/cards_controller.dart';
import 'package:kazzi_credit/features/cards/domain/payment_card.dart';
import 'package:kazzi_credit/features/notifications/application/notification_center.dart';
import 'package:kazzi_credit/features/profile/application/profile_controller.dart';
import 'package:kazzi_credit/features/transactions/application/transactions_controller.dart';
import 'package:kazzi_credit/features/transactions/presentation/widgets/transaction_tile.dart';
import 'package:kazzi_credit/features/wallet/presentation/widgets/card_stack.dart';
import 'package:kazzi_credit/features/wallet/presentation/widgets/card_summary.dart';
import 'package:kazzi_credit/features/wallet/presentation/widgets/pay_bill_sheet.dart';
import 'package:kazzi_credit/features/wallet/presentation/widgets/quick_actions.dart';
import 'package:kazzi_credit/features/wallet/presentation/widgets/wallet_header.dart';
import 'package:kazzi_credit/features/wallet/presentation/widgets/wallet_overview.dart';
import 'package:material_ui/material_ui.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String? _selectedId;
  String? _flippedId;

  /// Last `?card=` deep link handled, so it's applied only once.
  String? _linkedCard;

  void _select(String id) {
    ref.read(cardRevealProvider.notifier).hide();
    setState(() {
      _selectedId = id;
      _flippedId = null;
    });
  }

  void _toggleFlip(PaymentCard card) {
    final flipping = _flippedId != card.id;
    if (!flipping) ref.read(cardRevealProvider.notifier).hide();
    setState(() => _flippedId = flipping ? card.id : null);
  }

  Future<void> _toggleDetails(PaymentCard card) async {
    final reveal = ref.read(cardRevealProvider.notifier);
    if (ref.read(cardRevealProvider)?.cardId == card.id) {
      reveal.hide();
      setState(() => _flippedId = null);
      return;
    }
    final ok = await reauthenticate(
      context,
      ref,
      reason: 'Confirm it’s you to see card details',
    );
    if (!ok || !mounted) return;
    if (await reveal.show(card.id) && mounted) {
      setState(() => _flippedId = card.id);
    }
  }

  void _toggleFreeze(PaymentCard card) {
    final cards = ref.read(cardsProvider.notifier);
    final freeze = !card.frozen;
    cards.setFrozen(card.id, frozen: freeze);
    HapticFeedback.mediumImpact().ignore();
    showAppToast(
      context,
      freeze
          ? '${card.nickname} is frozen. New purchases will be declined.'
          : '${card.nickname} is active again',
      icon: freeze ? Icons.ac_unit_rounded : Icons.check_circle_rounded,
      tone: freeze ? ToastTone.neutral : ToastTone.success,
      onUndo: () => cards.setFrozen(card.id, frozen: !freeze),
    );
  }

  Future<void> _addCard() async {
    final id = await context.push<String>(AppRoutes.addCard);
    if (id != null && mounted) _select(id);
  }

  void _comingSoon(String what) =>
      showAppToast(context, '$what arrive in an upcoming update');

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardsProvider);
    final revealed = ref.watch(cardRevealProvider);
    final profile = ref.watch(profileProvider);
    final now = ref.watch(clockProvider)();
    final card =
        cards.where((c) => c.id == _selectedId).firstOrNull ??
        cards.firstOrNull;
    final isRevealed = card != null && revealed?.cardId == card.id;

    // Deep link from a notification: /home?card=<id>.
    final linked = GoRouterState.of(context).uri.queryParameters['card'];
    if (linked != null && linked != _linkedCard) {
      _linkedCard = linked;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && cards.any((c) => c.id == linked)) _select(linked);
      });
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: WalletHeader(
                name: profile.isEmpty ? 'there' : profile.firstName,
                initials: profile.initials,
                unread: ref.watch(unreadCountProvider),
                onProfile: () => context.go(AppRoutes.profile),
                onNotifications: () => context.push(AppRoutes.notifications),
              ),
            ),
            if (cards.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.xs,
                  AppSpacing.page,
                  AppSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: WalletOverview(cards: cards, now: now),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'My cards',
                  actionLabel: '+ Add card',
                  onAction: _addCard,
                ),
              ),
            ),
            if (card == null)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.add_card_rounded,
                  title: 'No cards yet',
                  message:
                      'Add a card to see your balance, due dates and every '
                      'purchase in one place.',
                  actionLabel: 'Add a card',
                  onAction: _addCard,
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                sliver: SliverToBoxAdapter(
                  child: CardStack(
                    cards: cards,
                    selectedId: card.id,
                    flippedId: _flippedId,
                    revealed: revealed,
                    onSelect: _select,
                    onFlip: _toggleFlip,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.xl,
                  AppSpacing.page,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuickActions(
                        actions: [
                          if (card.kind == CardKind.credit)
                            QuickAction(
                              icon: Icons.north_east_rounded,
                              label: 'Pay',
                              primary: true,
                              onTap: () => showPayBillSheet(context, card),
                            ),
                          QuickAction(
                            icon: Icons.ac_unit_rounded,
                            label: card.frozen ? 'Unfreeze' : 'Freeze',
                            color: const Color(0xFF0E7CB5),
                            highlighted: card.frozen,
                            onTap: () => _toggleFreeze(card),
                          ),
                          QuickAction(
                            icon: isRevealed
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            label: isRevealed ? 'Hide' : 'Details',
                            color: const Color(0xFF6B57E8),
                            highlighted: isRevealed,
                            onTap: () => _toggleDetails(card),
                          ),
                          QuickAction(
                            icon: Icons.description_outlined,
                            label: 'Statements',
                            color: const Color(0xFFD9622B),
                            onTap: () => _comingSoon('Statements'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Divider(color: context.colors.border),
                      const SizedBox(height: AppSpacing.lg),
                      CardSummary(card: card, now: now),
                    ],
                  ),
                ),
              ),
              ..._recentActivity(card, now),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  List<Widget> _recentActivity(PaymentCard card, DateTime now) {
    final txs = ref.watch(cardTransactionsProvider(card.id)).take(5).toList();
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xl,
          AppSpacing.sm,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Recent activity',
            actionLabel: 'See all',
            onAction: () => context.go(AppRoutes.transactions),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        sliver: txs.isEmpty
            ? const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'No activity yet',
                  message: 'Purchases on this card will show up here.',
                ),
              )
            : SliverList.list(
                children: [
                  for (final tx in txs)
                    TransactionTile(
                      key: ValueKey(tx.id),
                      tx: tx,
                      now: now,
                      heroSource: 'wallet',
                      onTap: () => context.push(
                        AppRoutes.transactionDetail(tx.id, from: 'wallet'),
                      ),
                    ),
                ],
              ),
      ),
    ];
  }
}
