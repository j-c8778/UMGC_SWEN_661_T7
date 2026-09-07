import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'undo.dart';
import 'screens/landing_screen.dart';
import 'screens/create_account_screen.dart';
import 'screens/biometrics_screen.dart';
import 'screens/sign_in_bio_screen.dart';
import 'screens/sign_in_pass_screen.dart';
import 'screens/today_screen.dart';
import 'screens/medications_screen.dart';
// import 'screens/schedule_screen.dart';
// import 'screens/symptoms_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/msg_thread_screen.dart';
// import 'screens/account_screen.dart';
// import 'screens/calling_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => ActionHistory()),
      ],
      child: const CareConnectApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/landing',
  routes: [
    GoRoute(path: '/landing', builder: (_, __) => const LandingScreen()),
    GoRoute(
        path: '/create-account',
        builder: (_, __) => const CreateAccountScreen()),
    GoRoute(path: '/biometrics', builder: (_, __) => const BiometricsScreen()),
    GoRoute(path: '/sign-in-bio', builder: (_, __) => const SignInBioScreen()),
    GoRoute(
        path: '/sign-in-pass', builder: (_, __) => const SignInPassScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
        GoRoute(
            path: '/medications',
            builder: (_, __) => const MedicationsScreen()),
        // GoRoute(path: '/schedule',    builder: (_, __) => const ScheduleScreen()),
        // GoRoute(path: '/symptoms',    builder: (_, __) => const SymptomsScreen()),
        GoRoute(path: '/messages', builder: (_, __) => const MessagesScreen()),
        GoRoute(
          path: '/messages/:threadId',
          builder: (_, state) => MsgThreadScreen(
              threadId: int.parse(state.pathParameters['threadId']!)),
        ),
        // GoRoute(path: '/account',     builder: (_, __) => const AccountScreen()),
        // GoRoute(
        //   path: '/calling/:contactId',
        //   builder: (_, state) => CallingScreen(contactId: int.parse(state.pathParameters['contactId']!)),
        // ),
      ],
    ),
  ],
);

class CareConnectApp extends StatelessWidget {
  const CareConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    return MaterialApp.router(
      title: 'CareConnect',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(false),
      darkTheme: buildTheme(true),
      themeMode: themeNotifier.isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
    );
  }
}

// ── Shared nav items ────────────────────────────────────────────────────────────

const _navItems = [
  (path: '/today', label: 'Today', icon: '🏠'),
  (path: '/medications', label: 'Medications', icon: '💊'),
  (path: '/messages', label: 'Messages', icon: '💬'),
  (path: '/schedule', label: 'Schedule', icon: '📅'),
  (path: '/symptoms', label: 'Symptoms', icon: '📊'),
  (path: '/account', label: 'Account', icon: '👤'),
];

// ── App shell with adaptive bottom nav ─────────────────────────────────────────

class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollUp() {
    final viewport = _scrollController.hasClients
        ? _scrollController.position.viewportDimension
        : 300.0;
    _scrollBy(-viewport * 0.8);
  }

  void _scrollDown() {
    final viewport = _scrollController.hasClients
        ? _scrollController.position.viewportDimension
        : 300.0;
    _scrollBy(viewport * 0.8);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.watch<ThemeNotifier>().scheme;
    final location = GoRouterState.of(context).matchedLocation;
    final isThread = location.startsWith('/messages/');
    final isCalling = location.startsWith('/calling/');
    final isFullScreen = isThread || isCalling;
    final currentIdx = _navItems.indexWhere((n) => location.startsWith(n.path));

    return Scaffold(
      backgroundColor: scheme.bg,
      body: ListenableProvider<ScrollController>.value(
        value: _scrollController,
        child: widget.child,
      ),
      floatingActionButton: const _UndoFab(),
      bottomNavigationBar: isFullScreen
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accessibility bar
                _AccessBar(
                  scheme: scheme,
                  onScrollUp: _scrollUp,
                  onScrollDown: _scrollDown,
                ),
                // Bottom nav
                _BottomNav(
                  scheme: scheme,
                  currentIdx: currentIdx < 0 ? 0 : currentIdx,
                  onTap: (i) => context.go(_navItems[i].path),
                ),
              ],
            ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final CScheme scheme;
  final int currentIdx;
  final void Function(int) onTap;
  const _BottomNav(
      {required this.scheme, required this.currentIdx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.border)),
      ),
      child: Row(
        children: List.generate(_navItems.length, (i) {
          final active = i == currentIdx;
          final item = _navItems[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  if (active)
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(4)),
                      ),
                    ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: active ? scheme.primary : scheme.sub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AccessBar extends StatelessWidget {
  final CScheme scheme;
  final VoidCallback onScrollUp;
  final VoidCallback onScrollDown;
  const _AccessBar({
    required this.scheme,
    required this.onScrollUp,
    required this.onScrollDown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _accessBtn(context, '↑', 'Scroll up', scheme, onTap: onScrollUp),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 72,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎤', style: TextStyle(fontSize: 20)),
                  Text('Voice',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _accessBtn(context, '↓', 'Scroll down', scheme, onTap: onScrollDown),
        ],
      ),
    );
  }

  Widget _accessBtn(
      BuildContext context, String icon, String label, CScheme scheme,
      {required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: scheme.surface2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.border, width: 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: TextStyle(fontSize: 20, color: scheme.sub)),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.sub,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating undo button + history sheet ────────────────────────────────────────

class _UndoFab extends StatelessWidget {
  const _UndoFab();

  @override
  Widget build(BuildContext context) {
    final scheme = context.watch<ThemeNotifier>().scheme;
    final count = context.watch<ActionHistory>().actions.length;

    return FloatingActionButton(
      heroTag: 'undoFab',
      backgroundColor: count > 0 ? scheme.primary : scheme.surface2,
      foregroundColor: count > 0 ? Colors.white : scheme.sub,
      elevation: count > 0 ? 4 : 1,
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _UndoSheet(),
      ),
      child: Badge(
        label: Text('$count'),
        isLabelVisible: count > 0,
        backgroundColor: const Color(0xFFC53030),
        child: const Icon(Icons.undo_rounded),
      ),
    );
  }
}

class _UndoSheet extends StatelessWidget {
  const _UndoSheet();

  @override
  Widget build(BuildContext context) {
    final scheme = context.watch<ThemeNotifier>().scheme;
    final actions = context.watch<ActionHistory>().actions;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: scheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent changes',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: scheme.text),
                      ),
                    ),
                    if (actions.isNotEmpty)
                      TextButton(
                        onPressed: () => context.read<ActionHistory>().clear(),
                        child: Text('Clear all',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.sub)),
                      ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: scheme.sub),
                      tooltip: 'Close',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              if (actions.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  child: Text('No changes to undo yet.',
                      style: TextStyle(fontSize: 14, color: scheme.sub)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                    itemCount: actions.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: scheme.border),
                    itemBuilder: (context, i) {
                      final action = actions[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(action.description,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.text)),
                                  const SizedBox(height: 2),
                                  Text(_relativeTime(action.timestamp),
                                      style: TextStyle(fontSize: 12, color: scheme.muted)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => context.read<ActionHistory>().undo(action.id),
                              child: const Text('Undo', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
