import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppColors.white.withOpacity(0.1)
                  : AppColors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.getTextColor(isDark),
              size: 16,
            ),
          ),
        ),
        title: Text(
          'Aide & Support',
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            _buildSearchBar(isDark),
            const SizedBox(height: 24),
            
            // Quick Help Cards
            _buildQuickHelpCards(isDark),
            const SizedBox(height: 32),
            
            // FAQ Section
            _buildFAQSection(isDark),
            const SizedBox(height: 32),
            
            // Contact Section
            _buildContactSection(isDark),
            const SizedBox(height: 32),
            
            // Resources Section
            _buildResourcesSection(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(isDark),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? AppColors.black.withOpacity(0.2)
                : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        style: TextStyle(
          color: AppColors.getTextColor(isDark),
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher une aide...',
          hintStyle: TextStyle(
            color: AppColors.getTextColor(isDark, type: TextType.secondary),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.getTextColor(isDark, type: TextType.secondary),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildQuickHelpCards(bool isDark) {
    final cards = [
      {
        'title': 'Premiers pas',
        'subtitle': 'Guide de démarrage rapide',
        'icon': Icons.rocket_launch,
        'color': AppColors.success,
        'route': '/getting-started',
      },
      {
        'title': 'Ajouter un enfant',
        'subtitle': 'Comment gérer vos enfants',
        'icon': Icons.child_care,
        'color': AppColors.primary,
        'route': '/add-child',
      },
      {
        'title': 'Paiements',
        'subtitle': 'Gérer les frais scolaires',
        'icon': Icons.payment,
        'color': AppColors.warning,
        'route': '/payments',
      },
      {
        'title': 'Notifications',
        'subtitle': 'Configurer les alertes',
        'icon': Icons.notifications,
        'color': AppColors.info,
        'route': '/notifications',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aide Rapide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(isDark),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return _buildHelpCard(card, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildHelpCard(Map<String, dynamic> card, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to help topic
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getBorderColor(isDark),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? AppColors.black.withOpacity(0.2)
                    : AppColors.shadowLight,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (card['color'] as Color).toSurface(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  card['icon'] as IconData,
                  color: card['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                card['title'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(isDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                card['subtitle'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQSection(bool isDark) {
    final faqs = [
      {
        'question': 'Comment ajouter un enfant à mon compte ?',
        'answer': 'Allez dans l\'écran d\'accueil, cliquez sur le bouton "+" en bas à droite et remplissez les informations de votre enfant.',
        'category': 'Compte',
      },
      {
        'question': 'Comment payer les frais scolaires ?',
        'answer': 'Naviguez vers l\'écran "Frais" depuis le menu, sélectionnez l\'enfant et le type de frais, puis choisissez votre méthode de paiement.',
        'category': 'Paiements',
      },
      {
        'question': 'Comment contacter un enseignant ?',
        'answer': 'Depuis le profil de votre enfant, cliquez sur "Établissement" puis sur "Contact" pour accéder aux coordonnées des enseignants.',
        'category': 'Communication',
      },
      {
        'question': 'Mes données sont-elles sécurisées ?',
        'answer': 'Oui, toutes vos données sont chiffrées et protégées conformément au RGPD. Nous ne partageons jamais vos informations sans consentement.',
        'category': 'Sécurité',
      },
    ];

    final filteredFAQs = _searchQuery.isEmpty
        ? faqs
        : faqs.where((faq) =>
            (faq['question'] as String).toLowerCase().contains(_searchQuery) ||
            (faq['answer'] as String).toLowerCase().contains(_searchQuery) ||
            (faq['category'] as String).toLowerCase().contains(_searchQuery)
          ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions Fréquentes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(isDark),
          ),
        ),
        const SizedBox(height: 16),
        if (filteredFAQs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.getBorderColor(isDark),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucun résultat trouvé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Essayez avec d\'autres mots-clés',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextColor(isDark, type: TextType.secondary),
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredFAQs.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            return _buildFAQItem(faq, isDark, index);
          }).toList(),
      ],
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> faq, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(isDark),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? AppColors.black.withOpacity(0.2)
                : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.toSurface(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.help_outline,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          faq['question'] as String,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(isDark),
          ),
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.toSurface(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            faq['category'] as String,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        iconColor: AppColors.getTextColor(isDark, type: TextType.secondary),
        collapsedIconColor: AppColors.getTextColor(isDark, type: TextType.secondary),
        children: [
          Text(
            faq['answer'] as String,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextColor(isDark, type: TextType.secondary),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contactez-nous',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildContactTile(
                'Support par Chat',
                'Discutez avec notre équipe',
                Icons.chat,
                const Color(0xFF4CAF50),
                isDark,
                onTap: () => _launchChat(),
              ),
              _buildContactTile(
                'Support par Email',
                'support@ecole-app.com',
                Icons.email,
                const Color(0xFF2196F3),
                isDark,
                onTap: () => _launchEmail(),
              ),
              _buildContactTile(
                'Support Téléphonique',
                '+33 1 234 567 890',
                Icons.phone,
                const Color(0xFFFF9800),
                isDark,
                onTap: () => _launchPhone(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile(String title, String subtitle, IconData icon, Color color, bool isDark, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesSection(bool isDark) {
    final resources = [
      {
        'title': 'Guide Complet',
        'subtitle': 'Manuel d\'utilisation détaillé',
        'icon': Icons.menu_book,
        'color': const Color(0xFF9C27B0),
        'url': 'https://example.com/guide',
      },
      {
        'title': 'Vidéos Tutoriel',
        'subtitle': 'Apprenez en vidéo',
        'icon': Icons.video_library,
        'color': const Color(0xFFF44336),
        'url': 'https://example.com/videos',
      },
      {
        'title': 'Blog',
        'subtitle': 'Actualités et conseils',
        'icon': Icons.article,
        'color': const Color(0xFF00BCD4),
        'url': 'https://example.com/blog',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ressources',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...resources.map((resource) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildResourceTile(resource, isDark),
        )).toList(),
      ],
    );
  }

  Widget _buildResourceTile(Map<String, dynamic> resource, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchURL(resource['url'] as String),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (resource['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  resource['icon'] as IconData,
                  color: resource['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['title'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      resource['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    // TODO: Ajouter le package url_launcher aux dépendances
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture de $url...'),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }

  Future<void> _launchEmail() async {
    // TODO: Ajouter le package url_launcher aux dépendances
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture du client email...'),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }

  Future<void> _launchPhone() async {
    // TODO: Ajouter le package url_launcher aux dépendances
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouverture du téléphone...'),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }

  Future<void> _launchChat() async {
    // Implement chat functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le chat sera bientôt disponible!'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }
}
