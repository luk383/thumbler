import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wolf_lab/app/constants/app_colors.dart';
import 'package:wolf_lab/features/health/state/health_controller.dart';
import 'package:wolf_lab/features/strava/state/strava_controller.dart';

// ── Shell ─────────────────────────────────────────────────────────────────────
// Wraps the 3 main tab screens (GO / HEALTH / JOURNEY).
// Each tab screen provides its own Scaffold + WajeAppBar.
// This shell only adds the persistent bottom navigation bar.

class WajeShell extends StatelessWidget {
  const WajeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: navigationShell,
      bottomNavigationBar: _WajeBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ── Shared AppBar ─────────────────────────────────────────────────────────────
// Use this as the `appBar` of every top-level tab screen.

class WajeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const WajeAppBar({
    super.key,
    this.actions = const [],
    this.bottom,
    this.bottomHeight = 0,
  });

  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final double bottomHeight;

  @override
  Size get preferredSize => Size.fromHeight(72 + bottomHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      toolbarHeight: 72,
      backgroundColor: AppColors.darkBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: _WajeWordmark(),
      actions: [
        ...actions,
        _SyncButton(),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 22),
          color: AppColors.textSecondary,
          onPressed: () => context.push('/settings'),
          tooltip: 'Settings',
        ),
      ],
      bottom: bottom,
    );
  }
}

class _SyncButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncingStrava = ref.watch(
        stravaControllerProvider.select((s) => s.isConnecting));
    final isSyncingHealth = ref.watch(
        healthControllerProvider.select((s) => s.isSyncing));
    final isSyncing = isSyncingStrava || isSyncingHealth;

    return IconButton(
      tooltip: 'Sincronizza tutto',
      icon: isSyncing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.orange,
              ),
            )
          : const Icon(Icons.sync, size: 22),
      color: AppColors.textSecondary,
      onPressed: isSyncing ? null : () => _syncAll(ref),
    );
  }

  Future<void> _syncAll(WidgetRef ref) async {
    await Future.wait([
      ref.read(stravaControllerProvider.notifier).syncActivities(),
      ref.read(healthControllerProvider.notifier).syncHealthConnect(),
    ]);
  }
}

class _WajeWordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF7A00), Color(0xFFFFAA44)],
          ).createShader(bounds),
          child: const Text(
            'WAJE',
            style: TextStyle(
              fontFamily: 'Impact',
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              height: 1,
            ),
          ),
        ),
        const Text(
          'WORK ALTITUDE JOURNEY EVOLUTION',
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
            color: AppColors.textSecondary,
            height: 1,
          ),
        ),
      ],
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────

class _WajeBottomNav extends StatelessWidget {
  const _WajeBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(icon: Icons.directions_bike_outlined, label: 'GO'),
    _NavItem(icon: Icons.favorite_outline, label: 'HEALTH'),
    _NavItem(icon: Icons.explore_outlined, label: 'JOURNEY'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkPanel,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final selected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: selected ? AppColors.orange : AppColors.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: selected ? AppColors.orange : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2,
                      width: selected ? 20 : 0,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
