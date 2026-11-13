import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../game/config.dart';
import '../game/game_controller.dart';
import '../steps/step_source.dart';
import 'format.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.game,
    this.fakeSteps,
    this.awayEarnings = 0,
  });

  final GameController game;

  /// Present only while real step data is not wired up.
  final FakeStepSource? fakeSteps;

  /// Coins earned while the app was closed, shown once on start.
  final double awayEarnings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Timer _ticker;
  late final AppLifecycleListener _lifecycle;
  int _ticks = 0;

  GameController get game => widget.game;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      game.tick();
      if (++_ticks % 15 == 0) game.save();
    });
    _lifecycle = AppLifecycleListener(
      onResume: () async => _showAway(await game.resume()),
      onPause: game.save,
    );
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showAway(widget.awayEarnings));
  }

  @override
  void dispose() {
    _ticker.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _showAway(double coins) {
    if (!mounted || coins < 1) return;
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Welcome back'),
        content: Text('Your helpers earned ${compact(coins)} coins '
            'while you were away.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Nice'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _addFakeSteps(int n) async {
    widget.fakeSteps!.addSteps(n);
    final r = await game.syncSteps();
    if (r.bonusCoins > 0) {
      _snack('Milestone! +${compact(r.bonusCoins)} bonus coins');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('1 Million Steps')),
        floatingActionButton: widget.fakeSteps != null && kDebugMode
            ? FloatingActionButton.extended(
                onPressed: () => _addFakeSteps(1000),
                icon: const Icon(Icons.directions_walk),
                label: const Text('+1,000 steps (debug)'),
              )
            : null,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            _ProgressCard(game: game),
            const SizedBox(height: 12),
            _WalletCard(game: game, onCollect: () {
              final c = game.collect();
              if (c > 0) _snack('+${compact(c)} coins');
            }),
            const SizedBox(height: 12),
            _ShoesCard(game: game),
            const SizedBox(height: 20),
            Text('Helpers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < generatorDefs.length; i++)
              _GeneratorTile(game: game, index: i),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = game.state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lifetime steps', style: t.labelLarge),
            const SizedBox(height: 4),
            Text(groupThousands(s.lifetimeSteps), style: t.displaySmall),
            Text('of ${groupThousands(Tuning.goalSteps)}', style: t.bodyMedium),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: game.progress, minHeight: 10),
            ),
            const SizedBox(height: 6),
            Text('${(game.progress * 100).toStringAsFixed(2)}%',
                style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.game, required this.onCollect});
  final GameController game;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = game.state;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 8),
                Text(compact(s.coins), style: t.headlineMedium),
                const Spacer(),
                Text('${compact(game.incomePerMinute)}/min',
                    style: t.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: s.pendingSteps > 0 ? onCollect : null,
              icon: const Icon(Icons.download),
              label: Text(s.pendingSteps > 0
                  ? 'Collect ${groupThousands(s.pendingSteps)} steps '
                      '→ ${compact(game.pendingCoins)} coins'
                  : 'Walk to earn steps'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShoesCard extends StatelessWidget {
  const _ShoesCard({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final cost = game.nextShoeCost;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.hiking, size: 32),
        title: Text('Shoes · level ${game.state.shoeLevel}'),
        subtitle: Text('${compact(game.coinsPerStep)} coins per step'),
        trailing: FilledButton.tonal(
          onPressed: game.state.coins >= cost ? game.buyShoes : null,
          child: Text(compact(cost)),
        ),
      ),
    );
  }
}

class _GeneratorTile extends StatelessWidget {
  const _GeneratorTile({required this.game, required this.index});
  final GameController game;
  final int index;

  @override
  Widget build(BuildContext context) {
    final def = generatorDefs[index];
    final owned = game.state.generatorsOwned[index];
    if (!game.isUnlocked(index)) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(def.name),
          subtitle: Text('Unlocks at ${groupThousands(def.unlockAt)} steps'),
          enabled: false,
        ),
      );
    }
    final cost = game.generatorPrice(index);
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('$owned')),
        title: Text(def.name),
        subtitle: Text('${compact(def.perMinute)}/min each'),
        trailing: FilledButton.tonal(
          onPressed:
              game.state.coins >= cost ? () => game.buyGenerator(index) : null,
          child: Text(compact(cost)),
        ),
      ),
    );
  }
}
