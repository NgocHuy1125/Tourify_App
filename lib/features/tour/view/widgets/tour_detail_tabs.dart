import 'package:flutter/material.dart';

class StickyTabPlaceholder extends StatelessWidget {
  final List<String> titles;
  final ValueNotifier<int> activeSection;
  final ValueNotifier<bool> notifier;
  final ValueChanged<int> onTap;

  const StickyTabPlaceholder({
    super.key,
    required this.titles,
    required this.activeSection,
    required this.notifier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, showSticky, __) {
        if (showSticky) return const SizedBox(height: 60);
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ValueListenableBuilder<int>(
            valueListenable: activeSection,
            builder: (_, active, __) {
              return TabBarRow(
                titles: titles,
                activeIndex: active,
                onTap: onTap,
              );
            },
          ),
        );
      },
    );
  }
}

class PinnedTabs extends StatelessWidget {
  final List<String> titles;
  final ValueNotifier<int> activeSection;
  final ValueChanged<int> onTap;

  const PinnedTabs({
    super.key,
    required this.titles,
    required this.activeSection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white,
      child: ValueListenableBuilder<int>(
        valueListenable: activeSection,
        builder: (_, active, __) {
          return TabBarRow(titles: titles, activeIndex: active, onTap: onTap);
        },
      ),
    );
  }
}

class TabBarRow extends StatelessWidget {
  final List<String> titles;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const TabBarRow({
    super.key,
    required this.titles,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final isActive = index == activeIndex;
          return GestureDetector(
            onTap: () => onTap(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  titles[index],
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? const Color(0xFFFF5B00) : Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: isActive ? 60 : 0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5B00),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemCount: titles.length,
      ),
    );
  }
}
