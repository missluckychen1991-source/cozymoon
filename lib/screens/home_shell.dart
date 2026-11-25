import 'package:flutter/material.dart';

import 'coming_soon_screen.dart';
import 'home_screen.dart';
import 'tea_table_screen.dart';

/// Bottom navigation: Home, Tea Table, Cozy Nook, Learn.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int index = 0;

  void goTo(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    const pages = [
      HomeScreen(),
      TeaTableScreen(),
      ComingSoonScreen(
        title: 'Cozy Nook',
        emoji: '🛋️',
        text:
            'Brain-free games, tiny stories, calm videos and soft sounds. Coming in week 3.',
      ),
      ComingSoonScreen(
        title: 'Learn',
        emoji: '✨',
        text:
            "Today's 3 gentle steps about your body and aging well. Coming in week 4.",
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: goTo,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.emoji_food_beverage_outlined),
              selectedIcon: Icon(Icons.emoji_food_beverage),
              label: 'Tea Table'),
          NavigationDestination(
              icon: Icon(Icons.weekend_outlined),
              selectedIcon: Icon(Icons.weekend),
              label: 'Cozy Nook'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Learn'),
        ],
      ),
    );
  }
}
