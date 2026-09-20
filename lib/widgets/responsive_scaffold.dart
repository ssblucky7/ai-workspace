import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routing/route_names.dart';
import '../../providers/theme_provider.dart';

/// Adaptive navigation shell for the whole protected area.
///
/// - Narrow screens (< 600dp): NavigationBar at the bottom with animated transitions.
/// - Wide screens (>= 1000dp): permanent NavigationRail drawer.
/// - Medium screens (600-999dp): collapsible rail with animated expand/collapse.
///
/// The current destination is derived from the active route so state stays
/// consistent when the router redirects (e.g. after sign-out).
class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.title,
    this.fab,
    this.enableRailAnimation = true,
  });

  final Widget body;
  final String? title;
  final Widget? fab;
  final bool enableRailAnimation;

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold>
    with SingleTickerProviderStateMixin {
  static const double _tabletBreakpoint = 600;
  static const double _wideBreakpoint = 1000;

  late final AnimationController _railAnimationController;
  late final Animation<double> _railWidthAnimation;
  bool _isRailExtended = false;

  @override
  void initState() {
    super.initState();
    _railAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _railWidthAnimation = Tween<double>(begin: 72, end: 240).animate(
      CurvedAnimation(
        parent: _railAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _railAnimationController.dispose();
    super.dispose();
  }

  int _destinationFor(String location) {
    // Chat screen is handled separately (not in shell), so check for it first
    if (location.startsWith('/chat')) return 0;
    if (location.startsWith(RouteNames.conversationHistoryPath)) return 0;
    if (location.startsWith(RouteNames.aiProvidersPath)) return 1;
    if (location.startsWith(RouteNames.settingsPath)) return 2;
    if (location.startsWith(RouteNames.homePath)) return 0;
    if (location.startsWith(RouteNames.profilePath)) return 2;
    if (location.startsWith(RouteNames.aboutPath)) return 2;
    return -1;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (index) {
      case 0:
        if (!location.startsWith(RouteNames.homePath) &&
            !location.startsWith(RouteNames.conversationHistoryPath)) {
          context.go(RouteNames.homePath);
        }
        break;
      case 1:
        if (!location.startsWith(RouteNames.aiProvidersPath)) {
          context.go(RouteNames.aiProvidersPath);
        }
        break;
      case 2:
        if (!location.startsWith(RouteNames.settingsPath) &&
            !location.startsWith(RouteNames.profilePath) &&
            !location.startsWith(RouteNames.aboutPath)) {
          context.go(RouteNames.settingsPath);
        }
        break;
    }
  }

  static const _destinations = [
    (
      icon: Icon(Icons.chat_bubble_outline),
      selectedIcon: Icon(Icons.chat_bubble),
      label: 'Chats',
    ),
    (
      icon: Icon(Icons.dns_outlined),
      selectedIcon: Icon(Icons.dns),
      label: 'Providers',
    ),
    (
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _destinationFor(location);

    // Update rail extended state based on width
    final shouldExtend = width >= _wideBreakpoint;
    if (shouldExtend != _isRailExtended) {
      _isRailExtended = shouldExtend;
      if (widget.enableRailAnimation) {
        if (shouldExtend) {
          _railAnimationController.forward();
        } else {
          _railAnimationController.reverse();
        }
      }
    }

    if (width >= _tabletBreakpoint) {
      return _buildTabletLayout(context, width, selectedIndex);
    }

    // Phone layout: app bar + bottom navigation.
    return Scaffold(
      appBar: widget.title == null
          ? null
          : AppBar(
              title: Row(
                children: [
                  Icon(
                    Icons.hub_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(widget.title!),
                ],
              ),
              centerTitle: false,
              actions: [
                // Theme shortcut handled by parent screens where needed.
              ],
            ),
      body: SafeArea(child: widget.body),
      floatingActionButton: widget.fab,
      bottomNavigationBar: selectedIndex < 0
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex.clamp(0, 2),
              onDestinationSelected: (i) => _onDestinationSelected(context, i),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                    label: d.label,
                  ),
              ],
            ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    double width,
    int selectedIndex,
  ) {
    final railIndex = selectedIndex < 0 ? 0 : selectedIndex.clamp(0, 2);

    if (widget.enableRailAnimation && width < _wideBreakpoint) {
      // Animated collapsible rail for medium screens
      return Scaffold(
        body: Row(
          children: [
            AnimatedBuilder(
              animation: _railAnimationController,
              builder: (context, child) => SizedBox(
                width: _railWidthAnimation.value,
                child: _buildRail(context, railIndex),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(child: widget.body),
          ],
        ),
        floatingActionButton: widget.fab,
      );
    }

    // Wide screen: permanent extended rail
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: _isRailExtended ? 240 : 72,
            child: _buildRail(context, railIndex),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(child: widget.body),
        ],
      ),
      floatingActionButton: widget.fab,
    );
  }

  Widget _buildRail(BuildContext context, int selectedIndex) {
    final theme = Theme.of(context);
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) => _onDestinationSelected(context, i),
      extended: _isRailExtended,
      minWidth: 72,
      minExtendedWidth: 240,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 4),
            if (_isRailExtended)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  AppConstants.appName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
      trailing: _isRailExtended
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Toggle theme',
                    icon: Icon(
                      theme.brightness == Brightness.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    onPressed: () =>
                        context.read<ThemeProvider>().toggleLightDark(),
                  ),
                ],
              ),
            )
          : null,
      destinations: [
        for (final d in _destinations)
          NavigationRailDestination(
            icon: d.icon,
            selectedIcon: d.selectedIcon,
            label: Text(d.label),
          ),
      ],
    );
  }
}