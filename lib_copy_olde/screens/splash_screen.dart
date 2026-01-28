import 'package:flutter/material.dart';
import 'dart:async';
import 'intro_screen.dart';
import '../services/auth_service.dart';
import '../app.dart';
import '../config/app_colors.dart';

/// Écran de démarrage avec logo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _displayText = '';
  int _charIndex = 0;
  final String _fullText = 'Parent responsable';
  bool _showCursor = true;
  bool _showSubtitle = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _startTextAnimation();
  }

  void _startTextAnimation() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _animateText();
        _startCursorAnimation();
      }
    });
  }

  void _startCursorAnimation() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && _charIndex <= _fullText.length) {
        setState(() {
          _showCursor = !_showCursor;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _animateText() {
    if (_charIndex < _fullText.length) {
      setState(() {
        _displayText += _fullText[_charIndex];
        _charIndex++;
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _animateText();
        }
      });
    } else {
      // L'animation du texte est terminée, on arrête le curseur et on affiche le sous-titre
      setState(() {
        _showCursor = false;
      });
      
      // Afficher le sous-titre avec un effet de fondu après 300ms
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _showSubtitle = true;
          });
        }
      });
      
      // Attendre 2 secondes après l'affichage du sous-titre avant de rediriger
      Future.delayed(const Duration(seconds: 2), () {
        _navigateToLogin();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToLogin() async {
    if (mounted) {
      // Vérifier si une session existe
      final hasSession = await AuthService.instance.loadSavedSession();
      if (hasSession && AuthService.instance.isLoggedIn) {
        // Connexion automatique
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const App()),
        );
      } else {
        // Aller à l'écran d'introduction
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const IntroScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.pureBlack,
                    AppColors.pureBlack,
                  ]
                : [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Contenu principal
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 140,
                            height: 140,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(
                                'assets/images/logo-app.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          '$_displayText${_showCursor ? '|' : ''}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return AnimatedOpacity(
                        opacity: _showSubtitle ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          'Suivi scolaire simplifié',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Footer en bas
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Développé par',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                    ),
                    const SizedBox(height: 4),
                    // Logo développeur (placeholder)
                    Container(
                      width: 80,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          'LOGO',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

