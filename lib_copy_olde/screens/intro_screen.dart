import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'login_screen.dart';

/// Écran d'introduction avec slider auto-play
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  // Données des slides avec icônes et couleurs
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Parent responsable',
      'subtitle': 'Suivi scolaire simplifié',
      'description': 'Accédez à toutes les informations scolaires de votre enfant',
      'icon': Icons.school,
      'color': AppColors.primary,
      'features': [
        {'icon': Icons.grade, 'title': 'Suivi des notes', 'desc': 'Consultez les résultats scolaires de votre enfant', 'color': Colors.orange},
        {'icon': Icons.calendar_month, 'title': 'Emploi du temps', 'desc': 'Accédez aux horaires et activités', 'color': Colors.blue},
        {'icon': Icons.message, 'title': 'Communication', 'desc': 'Restez en contact avec l\'établissement', 'color': Colors.green},
      ],
      'hasFeatures': true,
    },
    // {
    //   'title': 'Suivi en temps réel',
    //   'subtitle': 'Ne manquez rien',
    //   'description': 'Consultez les notes, absences et comportements instantanément',
    //   'icon': Icons.grade,
    //   'color': Colors.orange,
    //   'hasFeatures': false,
    // },
    // {
    //   'title': 'Communication facile',
    //   'subtitle': 'Restez connecté',
    //   'description': 'Échangez directement avec les enseignants et l\'administration',
    //   'icon': Icons.message,
    //   'color': Colors.green,
    //   'hasFeatures': false,
    // },
    // {
    //   'title': 'Emploi du temps',
    //   'subtitle': 'Organisation optimale',
    //   'description': 'Planifiez votre semaine avec les horaires et activités de votre enfant',
    //   'icon': Icons.calendar_month,
    //   'color': Colors.purple,
    //   'hasFeatures': false,
    // },
  ];

  @override
  void initState() {
    super.initState();
    // Initialiser l'animation du bouton
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Démarrer l'animation en boucle
    _animationController.repeat(reverse: true);
    
    // Démarrer l'auto-play
    _startAutoPlay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (mounted) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      _startAutoPlay(); // Continuer le cycle
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Fond : noir en dark mode, blanc en light mode
          Container(
            width: double.infinity,
            height: double.infinity,
            color: isDark ? Colors.black : Colors.white,
          ),
          // Image de fond (différente selon le mode)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isDark 
                    ? 'assets/images/intro_background_dark.png'
                    : 'assets/images/intro_background.jpg'
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay semi-transparent pour la lisibilité (uniquement en light mode)
          if (!isDark)
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          // Dégradé blanc vers le bas (uniquement en light mode)
          if (!isDark)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(0.0, 0),
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xFFFFFFFF),
                    ],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
            ),
          // Contenu par-dessus l'image
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  
                  // Slider avec les slides
                  Expanded(
                    flex: 4,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        return _buildSlide(_slides[index]);
                      },
                    ),
                  ),
                  
                  // Indicateurs de slide
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _buildPageIndicators(),
                  ),
                  
                  const Spacer(flex: 1),
                  
                  // Bouton principal
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: SizedBox(
                          width: 280, // Largeur réduite
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0, // Pas d'ombre
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28), // Angles très arrondis
                              ),
                              shadowColor: Colors.transparent, // Ombre transparente
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Commencer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    final hasFeatures = slide['hasFeatures'] as bool;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icône au-dessus de la carte
        Icon(
          slide['icon'] as IconData,
          size: 80,
          color: slide['color'] as Color,
        ),
        const SizedBox(height: 24),
        
        // Carte avec fond très subtile de la couleur du slide
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (slide['color'] as Color).withOpacity(0.3), // Fond plus visible (20% d'opacité)
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: hasFeatures 
              ? _buildFeaturesContent(slide)
              : _buildSimpleContent(slide),
        ),
      ],
    );
  }

  Widget _buildSimpleContent(Map<String, dynamic> slide) {
    return Column(
      children: [
        // Titre
        Text(
          slide['title'] as String,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Grand titre en blanc
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        
        // Description
        Text(
          slide['description'] as String,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesContent(Map<String, dynamic> slide) {
    final features = slide['features'] as List<Map<String, dynamic>>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Text(
          slide['title'] as String,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Grand titre en blanc
          ),
        ),
        const SizedBox(height: 20),
        
        // Liste des fonctionnalités
        ...features.map((feature) => _buildFeatureItem(
          feature['icon'] as IconData,
          feature['title'] as String,
          feature['desc'] as String,
          feature['color'] as Color,
        )).toList(),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // Titres en blanc
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < _slides.length; i++) {
      indicators.add(
        GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == i ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentPage == i ? Colors.white : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }
    return indicators;
  }
}