import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../build_flags.dart';
import '../../game/clock.dart';
import '../../game/game_controller.dart';
import '../../steps/step_source.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/debug_tools.dart';
import '../widgets/mascot.dart';
import '../widgets/result_dialog.dart';
import 'marathons_screen.dart';
import 'medals_screen.dart';
import 'race_screen.dart';
import 'shop_screen.dart';

/// The four top-level tabs and the app-wide sync loop.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.game,
    this.fakeSteps,
    this.debugClock,
    this.healthSteps = false,
  });

  final GameController game;

  /// Present only when steps are fake (test buttons).
  final FakeStepSource? fakeSteps;
  final DebugClock? debugClock;

  /// Steps come from Apple Health.
  final bool healthSteps;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  late final Timer _clock;
  late final AppLifecycleListener _lifecycle;
  bool _showingResults = false;

  GameController get game => widget.game;

  @override
  void initState() {
    super.initState();
    // Catches races that close while the app stays open.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => _sync());
    _lifecycle = AppLifecycleListener(onResume: _sync, onPause: game.save);
    WidgetsBinding.instance.addPostFrameCallback((_) => _showResults());
  }

  @override
  void dispose() {
    _clock.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Pulls steps, then shows any race that just finished or ran out of time.
  Future<void> _sync() async {
    await game.syncSteps();
    await _showResults();
  }

  Future<void> _showResults() async {
    if (_showingResults) return;
    _showingResults = true;
    try {
      for (final r in game.takeUnseenResults()) {
        if (!mounted) return;
        await showRaceResultDialog(context, r, look: MascotLook.of(game));
      }
    } finally {
      _showingResults = false;
    }
  }

  void _goTo(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final steps = widget.fakeSteps;
    return Scaffold(
      // Test buttons live on this outer Scaffold so its snackbars float
      // above them instead of covering them.
      floatingActionButton: _tab == 0 && steps != null && kTestTools
          ? DebugTools(
              game: game,
              steps: steps,
              clock: widget.debugClock,
              onSync: _sync,
            )
          : null,
      body: IndexedStack(
        index: _tab,
        children: [
          RaceScreen(
            game: game,
            healthSteps: widget.healthSteps,
            onSync: _sync,
            onBrowse: () => _goTo(1),
            onShop: () => _goTo(2),
          ),
          MarathonsScreen(game: game, onSync: _sync, onJoined: () => _goTo(0)),
          ShopScreen(game: game),
          MedalsScreen(game: game, onBrowse: () => _goTo(1)),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: GameColors.of(context).line,
              width: kClayBorder,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _goTo,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.directions_run_rounded),
              label: 'Yarış',
            ),
            NavigationDestination(
              icon: Icon(Icons.outlined_flag_rounded),
              selectedIcon: Icon(Icons.flag_rounded),
              label: 'Maratonlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Mağaza',
            ),
            NavigationDestination(
              icon: Icon(Icons.military_tech_outlined),
              selectedIcon: Icon(Icons.military_tech_rounded),
              label: 'Madalyalar',
            ),
          ],
        ),
      ),
    );
  }
}
