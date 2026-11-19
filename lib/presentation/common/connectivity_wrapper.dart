import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/current_tab_provider.dart';
import 'no_internet_screen.dart';

class ConnectivityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  ConsumerState<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends ConsumerState<ConnectivityWrapper> {
  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider);
    final currentTab = ref.watch(currentTabProvider);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: [
          // Keep underlying app alive to preserve forms, cart, routes, and auth state
          widget.child,

          // Smoothly present exact No Internet artwork overlay when offline
          if (!isOnline)
            Positioned.fill(
              child: Material(
                color: const Color(0xFFFAF8EF),
                child: NoInternetScreen(
                  showBottomNav: true,
                  currentTabIndex: currentTab,
                  onSelectTab: (tabIndex) {
                    ref.read(currentTabProvider.notifier).state = tabIndex;
                  },
                  onRetrySuccess: () {
                    ref.read(connectivityProvider.notifier).refreshAppData();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

