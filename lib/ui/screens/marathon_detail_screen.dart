import 'package:material_ui/material_ui.dart';

import '../../game/catalog.dart';
import '../../game/economy.dart' as eco;
import '../../game/game_controller.dart';
import '../../game/game_state.dart';
import '../../game/schedule.dart';
import '../format.dart';
import '../theme/tokens.dart';
import '../widgets/badges.dart';
import '../widgets/common.dart';
import '../widgets/race_widgets.dart';
import '../widgets/run_sections.dart';

/// A weekly race's details and the join button. Pops with `true` when the
/// player should land on the race tab.
class MarathonDetailScreen extends StatelessWidget {
  const MarathonDetailScreen({
    super.key,
    required this.game,
    required this.event,
  });

  final GameController game;
  final MarathonEvent event;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final t = Theme.of(context).textTheme;
        final course = event.course;
        final status = game.statusOf(event);
        final reason = _blockedReason(status);
        final canRun =
            status == EventStatus.open || status == EventStatus.running;

        return Scaffold(
          appBar: AppBar(actions: [CoinBalance(game.state.coins)]),
          body: ListView(
            padding: pagePadding(context),
            children: [
              CourseBanner(
                course: course,
                large: true,
                locked: status == EventStatus.locked,
              ),
              const SizedBox(height: AppSpace.s16),
              Text(course.blurb, style: t.bodyLarge),
              const SectionHeader('Parkur'),
              CourseFacts(
                course: course,
                timeValue: switch (status) {
                  EventStatus.upcoming => 'Henüz açılmadı',
                  EventStatus.locked when game.now.isBefore(event.opensAt) =>
                    'Henüz açılmadı',
                  _ => timeLeftLabel(game.daysLeft(event)),
                },
              ),
              GearBonusSection(game: game, course: course),
              const SectionHeader('Tahmin'),
              Text(_estimate(status), style: t.bodyLarge),
              const SectionHeader(
                'Ödüller',
                subtitle: 'Ne kadar hızlı bitirirsen madalyan o kadar parlak.',
              ),
              MedalTargets(
                course: course,
                raceDay: status == EventStatus.running ? game.raceDay : null,
              ),
            ],
          ),
          bottomNavigationBar: DetailCta(
            label: _buttonLabel(status),
            reason: reason,
            onPressed: canRun && reason == null
                ? () => _onPressed(context, status)
                : null,
          ),
        );
      },
    );
  }

  String _estimate(EventStatus status) {
    final course = event.course;
    final bonus = game.bonusFor(course);
    final running = status == EventStatus.running;
    final total = running
        ? game.stepsToFinish
        : eco.stepsFor(course.meters, bonus);
    final head = running
        ? 'Bitişe ~${groupThousands(total)} adım kaldı.'
        : 'Mevcut ekipmanınla bitirmek için ~${groupThousands(total)} adım.';
    if (status != EventStatus.open && !running) return head;
    return '$head Kalan sürede günde ~'
        '${groupThousands(game.stepsPerDayNeeded(event))} adım atman yeter.';
  }

  /// Why the button is disabled, if it is for a reason worth explaining.
  String? _blockedReason(EventStatus status) {
    if (status == EventStatus.locked) {
      final gate = stageUnlocking(event.course.length)!;
      return '${event.course.length.plural}, Kademe ${gate.tier} · '
          '${gate.course.name} bitince açılır.';
    }
    if (status == EventStatus.open && game.race != null) {
      return 'Aynı anda tek parkurda ilerleyebilirsin. '
          'Önce aktif yarışını bitir.';
    }
    return null;
  }

  String _buttonLabel(EventStatus status) => switch (status) {
    EventStatus.locked => 'Kilitli',
    EventStatus.open => 'Katıl',
    EventStatus.running => 'Yarışa dön',
    EventStatus.finished =>
      'Tamamlandı · ${game.resultFor(event)!.medal!.label} madalya',
    EventStatus.missed =>
      game.resultFor(event)!.outcome == RaceOutcome.withdrew
          ? 'Bu yarıştan çekildin'
          : 'Süre doldu',
    EventStatus.upcoming => 'Pazartesi açılır',
    EventStatus.closed => 'Kapandı',
  };

  Future<void> _onPressed(BuildContext context, EventStatus status) async {
    if (status == EventStatus.running) {
      Navigator.pop(context, true);
      return;
    }
    final error = await game.join(event);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (error) {
            JoinError.raceInProgress => 'Önce aktif yarışını bitir.',
            JoinError.notOpen => 'Bu yarış şu an açık değil.',
            JoinError.alreadyRun => 'Bu parkuru bu hafta zaten koştun.',
            JoinError.locked => 'Bu yarış henüz kilitli.',
          }),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Yarış başladı. Bol şans!')));
    Navigator.pop(context, true);
  }
}
