import 'package:flutter/material.dart';

/// Palette de couleurs unifiée basée sur le bleu
/// Design System pour l'application Parent Responsable
class AppColors {
  // Private constructor pour éviter l'instanciation
  AppColors._();

  // ============= COULEURS PRINCIPALES =============
  
  /// Bleu principal - Couleur dominante de l'application
  static const Color primary = Color(0xFF1976D2);
  
  /// Variantes de bleu principal
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primarySurface = Color(0xFFE3F2FD);
  
  /// Bleu secondaire pour les accents
  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryLight = Color(0xFF64B5F6);
  static const Color secondaryDark = Color(0xFF1976D2);

  // ============= COULEURS NEUTRES =============
  
  /// Blancs
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteSurface = Color(0xFFF8FAFC);
  static const Color whiteCard = Color(0xFFFFFFFF);
  
  /// Gris - Scale complète pour l'harmonie
  static const Color grey50 = Color(0xFFF8F9FA);
  static const Color grey100 = Color(0xFFF1F3F4);
  static const Color grey200 = Color(0xFFE8EAED);
  static const Color grey300 = Color(0xFFDADCE0);
  static const Color grey400 = Color(0xFFBDC1C6);
  static const Color grey500 = Color(0xFF9AA0A6);
  static const Color grey600 = Color(0xFF80868B);
  static const Color grey700 = Color(0xFF5F6368);
  static const Color grey800 = Color(0xFF3C4043);
  static const Color grey900 = Color(0xFF202124);
  
  /// Noirs
  static const Color black = Color(0xFF000000);
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black38 = Color(0x61000000);
  static const Color black12 = Color(0x1F000000);
  
  /// Couleurs de fond pures pour les écrans
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  
  /// Obtenir la couleur de fond pure selon le thème
  static Color getPureBackground(bool isDark) {
    return isDark ? pureBlack : pureWhite;
  }
  
  /// Obtenir la couleur de fond pure pour l'AppBar selon le thème
  static Color getPureAppBarBackground(bool isDark) {
    return isDark ? pureBlack : pureWhite;
  }

  // ============= COULEURS FONCTIONNELLES =============
  
  /// Succès - Harmonisé avec le bleu
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);
  static const Color successSurface = Color(0xFFE8F5E8);
  
  /// Erreur - Rouge équilibré
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color errorSurface = Color(0xFFFFEBEE);
  
  /// Attention - Orange harmonisé
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);
  static const Color warningSurface = Color(0xFFFFF3E0);
  
  /// Information - Variante de bleu
  static const Color info = Color(0xFF03A9F4);
  static const Color infoLight = Color(0xFF29B6F6);
  static const Color infoDark = Color(0xFF0288D1);
  static const Color infoSurface = Color(0xFFE1F5FE);

  // ============= COULEURS SPÉCIFIQUES =============
  
  /// Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F0F0F);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);
  
  /// Textes
  static const Color textPrimaryLight = Color(0xFF202124);
  static const Color textSecondaryLight = Color(0xFF5F6368);
  static const Color textTertiaryLight = Color(0xFF9AA0A6);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFBDC1C6);
  static const Color textTertiaryDark = Color(0xFF9AA0A6);
  
  /// Bordures et diviseurs
  static const Color borderLight = Color(0xFFE8EAED);
  static const Color borderDark = Color(0xFF333333);
  static const Color dividerLight = Color(0xFFE8EAED);
  static const Color dividerDark = Color(0xFF333333);
  
  /// Ombres
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // ============= GRADIENTS =============
  
  /// Gradient principal bleu
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradient secondaire
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradient de succès
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Gradient d'erreur
  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Gradient orange/warning
  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, warningDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Couleurs spéciales
  static const Color transparent = Color(0x00000000);

  // ============= MÉTHODES UTILITAIRES =============
  
  /// Obtenir la couleur appropriée selon le thème
  static Color adaptiveColor({
    required Color lightColor,
    required Color darkColor,
    required bool isDark,
  }) {
    return isDark ? darkColor : lightColor;
  }
  
  /// Obtenir la couleur de texte appropriée
  static Color getTextColor(bool isDark, {TextType type = TextType.primary}) {
    switch (type) {
      case TextType.primary:
        return adaptiveColor(
          lightColor: textPrimaryLight,
          darkColor: textPrimaryDark,
          isDark: isDark,
        );
      case TextType.secondary:
        return adaptiveColor(
          lightColor: textSecondaryLight,
          darkColor: textSecondaryDark,
          isDark: isDark,
        );
      case TextType.tertiary:
        return adaptiveColor(
          lightColor: textTertiaryLight,
          darkColor: textTertiaryDark,
          isDark: isDark,
        );
    }
  }
  
  /// Obtenir la couleur de fond appropriée
  static Color getBackgroundColor(bool isDark) {
    return adaptiveColor(
      lightColor: backgroundLight,
      darkColor: backgroundDark,
      isDark: isDark,
    );
  }
  
  /// Obtenir la couleur de surface appropriée
  static Color getSurfaceColor(bool isDark) {
    return adaptiveColor(
      lightColor: surfaceLight,
      darkColor: surfaceDark,
      isDark: isDark,
    );
  }
  
  /// Obtenir la couleur de bordure appropriée
  static Color getBorderColor(bool isDark) {
    return adaptiveColor(
      lightColor: borderLight,
      darkColor: borderDark,
      isDark: isDark,
    );
  }
}

/// Types de texte pour la méthode utilitaire
enum TextType {
  primary,
  secondary,
  tertiary,
}

/// Extension pour faciliter l'utilisation des couleurs
extension ColorExtensions on Color {
  /// Convertir une couleur en avec opacité
  Color withOpacity(double opacity) {
    return this.withOpacity(opacity);
  }
  
  /// Créer une surface colorée
  Color toSurface() {
    return this.withOpacity(0.1);
  }
  
  /// Créer une bordure colorée
  Color toBorder() {
    return this.withOpacity(0.2);
  }
}
