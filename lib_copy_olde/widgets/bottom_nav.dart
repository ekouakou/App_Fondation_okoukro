import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Barre de navigation inférieure
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getPureBackground(isDark),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? AppColors.black.withOpacity(0.3)
                : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.getBorderColor(isDark),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.getTextColor(isDark, type: TextType.secondary),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentIndex == 0 
                    ? AppColors.primary.toSurface()
                    : AppColors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home,
                size: 20,
              ),
            ),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentIndex == 1 
                    ? AppColors.primary.toSurface()
                    : AppColors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.message,
                size: 20,
              ),
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentIndex == 2 
                    ? AppColors.primary.toSurface()
                    : AppColors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.grade,
                size: 20,
              ),
            ),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: currentIndex == 3 
                    ? AppColors.primary.toSurface()
                    : AppColors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.more_horiz,
                size: 20,
              ),
            ),
            label: 'Plus',
          ),
        ],
      ),
    );
  }
}

