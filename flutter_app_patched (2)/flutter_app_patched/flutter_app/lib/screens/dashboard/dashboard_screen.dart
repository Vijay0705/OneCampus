import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../profile/profile_screen.dart';
import '../announcements_screen.dart';
import '../materials_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../bus/bus_screen.dart';
import '../canteen/canteen_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeScreen(),
    CanteenScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant_rounded),
            label: 'Canteen',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'OneCampus',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (_, theme, __) => IconButton(
              icon: Icon(
                theme.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: () => theme.setTheme(
                theme.isDarkMode ? ThemeMode.light : ThemeMode.dark,
              ),
              tooltip: 'Toggle theme',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeCard(userName: user?.name ?? 'Student'),
                const SizedBox(height: 24),
                _SectionLabel(label: 'Quick Access'),
                const SizedBox(height: 12),
                _FeatureGrid(),
                const SizedBox(height: 24),
                _SectionLabel(label: 'Quick Actions'),
                const SizedBox(height: 12),
                _QuickActions(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userName;
  const _WelcomeCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withBlue(220)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    _WelcomeChip(emoji: '🎓', label: 'Campus App'),
                    _WelcomeChip(emoji: '🔥', label: 'Hackathon 2026'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.school_rounded, size: 42, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _WelcomeChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _WelcomeChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$emoji $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      _Feature(
        icon: Icons.campaign_rounded,
        label: 'Announcements',
        emoji: '📢',
        color: const Color(0xFFFF5252),
        bgColor: const Color(0xFFFEE2E2),
        darkBg: const Color(0xFF7F1D1D),
        screen: const AnnouncementsScreen(),
      ),
      _Feature(
        icon: Icons.menu_book_rounded,
        label: 'Notes & QP',
        emoji: '📚',
        color: const Color(0xFF6C63FF),
        bgColor: const Color(0xFFEDE9FE),
        darkBg: const Color(0xFF3B0764),
        screen: const MaterialsScreen(),
      ),
      _Feature(
        icon: Icons.storefront_rounded,
        label: 'Marketplace',
        emoji: '🛒',
        color: const Color(0xFF00C9A7),
        bgColor: const Color(0xFFCCFBF1),
        darkBg: const Color(0xFF134E4A),
        screen: const MarketplaceScreen(),
      ),
      _Feature(
        icon: Icons.directions_bus_rounded,
        label: 'Bus Tracker',
        emoji: '🚌',
        color: const Color(0xFFFFB300),
        bgColor: const Color(0xFFFEF3C7),
        darkBg: const Color(0xFF78350F),
        screen: const BusScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: features.length,
      itemBuilder: (context, i) => _FeatureCard(feature: features[i]),
    );
  }
}

class _Feature {
  final IconData icon;
  final String label;
  final String emoji;
  final Color color;
  final Color bgColor;
  final Color darkBg;
  final Widget screen;
  const _Feature({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.darkBg,
    required this.screen,
  });
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? feature.darkBg : feature.bgColor;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, a, b) => feature.screen,
            transitionsBuilder: (_, a, b, child) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0.05, 0), end: Offset.zero)
                    .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
                child: child,
              ),
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(feature.icon, color: feature.color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    feature.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actions = [
      _QuickAction(
        icon: Icons.upload_file_rounded,
        color: const Color(0xFF6C63FF),
        label: 'Upload Notes',
        subtitle: 'Share with your classmates',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MaterialsScreen())),
      ),
      _QuickAction(
        icon: Icons.quiz_rounded,
        color: const Color(0xFFFFB300),
        label: 'Previous Year QP',
        subtitle: 'Prepare for exams',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MaterialsScreen())),
      ),
      _QuickAction(
        icon: Icons.sell_rounded,
        color: const Color(0xFF00C9A7),
        label: 'Sell Something',
        subtitle: 'List your items on marketplace',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      child: Column(
        children: actions
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  _QuickActionTile(action: e.value),
                  if (e.key < actions.length - 1)
                    Divider(
                      height: 1,
                      indent: 68,
                      color: cs.outline.withOpacity(0.3),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

class _QuickActionTile extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface,
                      )),
                  Text(action.subtitle,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: cs.onSurface,
        letterSpacing: -0.3,
      ),
    );
  }
}