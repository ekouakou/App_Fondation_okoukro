import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/theme_service.dart';

class CustomTabBar extends StatelessWidget {
  final TabController controller;
  final List<TabItem> tabs;
  final bool isScrollable;
  final EdgeInsets? margin;
  final double? height;

  const CustomTabBar({
    Key? key,
    required this.controller,
    required this.tabs,
    this.isScrollable = true,
    this.margin,
    this.height = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeService().isDarkMode;
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: height,
          margin: margin ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: isScrollable
              ? _buildScrollableTabs(isDarkMode)
              : _buildFixedTabs(isDarkMode),
        );
      },
    );
  }

  Widget _buildScrollableTabs(bool isDarkMode) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: tabs.length,
      itemBuilder: (context, index) => _buildTabItem(index, isDarkMode),
    );
  }

  Widget _buildFixedTabs(bool isDarkMode) {
    return Row(
      children: List.generate(
        tabs.length,
        (index) => Expanded(
          child: _buildTabItem(index, isDarkMode),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, bool isDarkMode) {
    final isSelected = controller.index == index;
    final tab = tabs[index];
    
    return GestureDetector(
      onTap: () => controller.animateTo(index),
      child: Container(
        margin: isScrollable 
            ? const EdgeInsets.only(right: 8)
            : const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: !isSelected ? AppColors.getSurfaceColor(isDarkMode) : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
          border: !isSelected
              ? Border.all(color: AppColors.getBorderColor(isDarkMode))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.icon != null) ...[
              Icon(
                tab.icon,
                size: 14, // Réduit de 16 à 14
                color: isSelected
                    ? Colors.white
                    : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
              ),
              const SizedBox(width: 4), // Réduit de 6 à 4
            ],
            Text(
              tab.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
              ),
            ),
            if (tab.badge != null) ...[
              const SizedBox(width: 4), // Réduit de 6 à 4
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Réduit
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(8), // Réduit de 10 à 8
                ),
                child: Text(
                  tab.badge!,
                  style: TextStyle(
                    fontSize: 9, // Réduit de 10 à 9
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TabItem {
  final String title;
  final IconData? icon;
  final String? badge;

  const TabItem({
    required this.title,
    this.icon,
    this.badge,
  });
}
