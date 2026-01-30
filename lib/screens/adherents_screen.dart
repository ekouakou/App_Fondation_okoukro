import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/adherent.dart';
import '../models/paiement.dart';
import '../providers/adherent_provider.dart';
import '../providers/paiement_provider.dart';
import '../providers/cotisation_provider.dart';
import '../services/theme_service.dart';
import '../config/app_colors.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import 'cotisations_screen.dart';

class AdherentsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AdherentsScreen> createState() => _AdherentsScreenState();
}

class _AdherentsScreenState extends ConsumerState<AdherentsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _fabAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _fabSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation pour le FloatingActionButton
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _fabSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    // Animation pour la liste
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Démarrer les animations
    _fabAnimationController.forward();
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adherentsAsync = ref.watch(adherentProvider);

    return Scaffold(
      backgroundColor: AppColors.getPureBackground(ThemeService().isDarkMode),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 8),
            Expanded(
              child: adherentsAsync.when(
                loading: () => const LoadingWidget(),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.error.toSurface(),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Erreur de chargement',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextColor(ThemeService().isDarkMode),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.getTextColor(ThemeService().isDarkMode, type: TextType.secondary),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(adherentProvider.notifier).loadAdherents(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (adherents) => _buildAdherentsList(adherents),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: SlideTransition(
              position: _fabSlideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: _showAddAdherentDialog,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  label: const Text(
                    'Ajouter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Header avec titre et compteur
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adhérents',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextColor(ThemeService().isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer(
                      builder: (context, ref, child) {
                        final adherentsAsync = ref.watch(adherentProvider);
                        return adherentsAsync.when(
                          data: (adherents) => Text(
                            '${adherents.length} adhérent(s)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.getTextColor(ThemeService().isDarkMode, type: TextType.secondary),
                            ),
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Bouton filtre
              Container(
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(ThemeService().isDarkMode),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getBorderColor(ThemeService().isDarkMode),
                  ),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.getTextColor(ThemeService().isDarkMode),
                  ),
                  onSelected: (value) {
                    if (value == 'import') {
                      _showImportDialog();
                    } else if (value == 'clear_all') {
                      _showClearAllDialog();
                    } else if (value == 'filter') {
                      _showFilterDialog();
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(
                            Icons.upload_file,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Importer liste',
                            style: TextStyle(
                              color: AppColors.getTextColor(ThemeService().isDarkMode),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Tout vider',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'filter',
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune,
                            color: AppColors.getTextColor(ThemeService().isDarkMode),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Filtrer',
                            style: TextStyle(
                              color: AppColors.getTextColor(ThemeService().isDarkMode),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de recherche améliorée
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(ThemeService().isDarkMode),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _searchQuery.isNotEmpty 
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.getBorderColor(ThemeService().isDarkMode),
                width: _searchQuery.isNotEmpty ? 2 : 1,
              ),
              boxShadow: _searchQuery.isNotEmpty ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.getTextColor(ThemeService().isDarkMode),
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, téléphone...',
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.getTextColor(ThemeService().isDarkMode, type: TextType.tertiary),
                ),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search,
                    color: _searchQuery.isNotEmpty 
                        ? AppColors.primary 
                        : AppColors.getTextColor(ThemeService().isDarkMode, type: TextType.secondary),
                    size: 20,
                  ),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.getTextColor(ThemeService().isDarkMode, type: TextType.secondary),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          tooltip: 'Effacer',
                        ),
                      )
                    : Container(
                        width: 48,
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.mic,
                          color: AppColors.getTextColor(ThemeService().isDarkMode, type: TextType.tertiary),
                          size: 20,
                        ),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onSubmitted: (value) {
                // Optionnel: action quand l'utilisateur soumet la recherche
              },
            ),
          ),
          // Suggestions de recherche rapide (optionnel)
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, index) {
                  final suggestions = ['Actifs', 'Inactifs', 'Récents', 'Favoris'];
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(suggestions[index]),
                      onSelected: (isSelected) {
                        // Implémenter la logique de filtre rapide
                      },
                      backgroundColor: AppColors.getSurfaceColor(ThemeService().isDarkMode),
                      selectedColor: AppColors.primarySurface,
                      labelStyle: TextStyle(
                        color: AppColors.getTextColor(ThemeService().isDarkMode, type: TextType.secondary),
                        fontSize: 12,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.getBorderColor(ThemeService().isDarkMode),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdherentsList(List<Adherent> adherents) {
    List<Adherent> filteredAdherents = _searchQuery.isEmpty
        ? adherents
        : ref.read(adherentProvider.notifier).searchAdherents(_searchQuery);

    if (filteredAdherents.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.people_outline,
        title: _searchQuery.isEmpty ? 'Aucun adhérent' : 'Aucun résultat',
        subtitle: _searchQuery.isEmpty
            ? 'Ajoutez votre premier adhérent'
            : 'Essayez une autre recherche',
        action: _searchQuery.isEmpty
            ? FloatingActionButton(
          onPressed: _showAddAdherentDialog,
          child: Icon(Icons.add),
        )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adherentProvider.notifier).loadAdherents();
        // Réinitialiser l'animation de la liste
        _listAnimationController.reset();
        _listAnimationController.forward();
      },
      child: ListView.builder(
        itemCount: filteredAdherents.length,
        itemBuilder: (context, index) {
          final adherent = filteredAdherents[index];
          return AnimatedBuilder(
            animation: _listAnimationController,
            builder: (context, child) {
              final animationDelay = (index * 100).clamp(0, 800);
              final animationValue = (_listAnimationController.value * 1000 - animationDelay) / 1000;
              
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _listAnimationController,
                  curve: Interval(
                    animationDelay / 1000,
                    math.min(1.0, (animationDelay + 300) / 1000),
                    curve: Curves.easeOutCubic,
                  ),
                )),
                child: FadeTransition(
                  opacity: Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      animationDelay / 1000,
                      math.min(1.0, (animationDelay + 300) / 1000),
                      curve: Curves.easeOut,
                    ),
                  )),
                  child: _buildAdherentCard(adherent),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAdherentCard(Adherent adherent) {
    final isDarkMode = ThemeService().isDarkMode;
    final isActive = adherent.estActif;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.getBorderColor(isDarkMode),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? Colors.black.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewAdherentDetails(adherent),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header avec avatar et informations principales
                Row(
                  children: [
                    // Avatar amélioré
                    Hero(
                      tag: 'avatar_${adherent.id}',
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: isActive 
                              ? AppColors.primaryGradient 
                              : LinearGradient(
                                  colors: [
                                    AppColors.grey400,
                                    AppColors.grey500,
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (isActive ? AppColors.primary : AppColors.grey400).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: adherent.photoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  adherent.photoUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 28,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 28,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Informations principales
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nom avec badge de statut
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  adherent.nomComplet,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.getTextColor(isDarkMode),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Badge de statut
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive 
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive 
                                        ? AppColors.success.withOpacity(0.3)
                                        : AppColors.error.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isActive 
                                            ? AppColors.success 
                                            : AppColors.error,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isActive ? 'Actif' : 'Inactif',
                                      style: TextStyle(
                                        color: isActive 
                                            ? AppColors.success 
                                            : AppColors.error,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Informations secondaires
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                adherent.telephone,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Adhésion: ${DateFormat('dd MMM yyyy').format(adherent.dateAdhesion)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Menu actions
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(value, adherent),
                      icon: Icon(
                        Icons.more_vert,
                        color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                color: AppColors.getTextColor(isDarkMode),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Voir les détails',
                                style: TextStyle(
                                  color: AppColors.getTextColor(isDarkMode),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Modifier',
                                style: TextStyle(
                                  color: AppColors.getTextColor(isDarkMode),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                adherent.estActif ? Icons.block_outlined : Icons.check_circle_outline,
                                color: adherent.estActif ? AppColors.warning : AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                adherent.estActif ? 'Désactiver' : 'Activer',
                                style: TextStyle(
                                  color: AppColors.getTextColor(isDarkMode),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'add_cotisation',
                          child: Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Ajouter cotisation',
                                style: TextStyle(
                                  color: AppColors.getTextColor(isDarkMode),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Supprimer',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Actions rapides (optionnel)
                if (!isActive) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.toSurface(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cet adhérent est actuellement inactif',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _toggleAdherentStatus(adherent),
                          child: Text(
                            'Réactiver',
                            style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Adherent adherent) {
    switch (action) {
      case 'view':
        _viewAdherentDetails(adherent);
        break;
      case 'edit':
        _showEditAdherentDialog(adherent);
        break;
      case 'toggle':
        _toggleAdherentStatus(adherent);
        break;
      case 'add_cotisation':
        _showAddCotisationDialog(adherent);
        break;
      case 'delete':
        _showDeleteConfirmation(adherent);
        break;
    }
  }

  void _viewAdherentDetails(Adherent adherent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdherentDetailsScreen(adherent: adherent),
      ),
    );
  }

  void _showAddAdherentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdherentFormScreen(),
    ).then((_) {
      ref.read(adherentProvider.notifier).loadAdherents();
    });
  }

  void _showEditAdherentDialog(Adherent adherent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdherentFormScreen(adherent: adherent),
    ).then((_) {
      ref.read(adherentProvider.notifier).loadAdherents();
    });
  }

  void _toggleAdherentStatus(Adherent adherent) {
    final updatedAdherent = adherent.copyWith(estActif: !adherent.estActif);
    ref.read(adherentProvider.notifier).updateAdherent(updatedAdherent);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          adherent.estActif ? 'Adhérent désactivé' : 'Adhérent activé',
        ),
      ),
    );
  }

  void _showAddCotisationDialog(Adherent adherent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CotisationFormScreen(adherent: adherent),
    );
  }

  void _showDeleteConfirmation(Adherent adherent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer l\'adhérent'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${adherent.nomComplet}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.annuler),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(adherentProvider.notifier).deleteAdherent(adherent.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Adhérent supprimé')),
              );
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text('⚠️ ATTENTION - Suppression totale'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action va SUPPRIMER DÉFINITIVEMENT:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              '❌ Tous les adhérents',
              '❌ Toutes les cotisations',
              '❌ Tout l\'historique des paiements',
              '❌ Tous les rapports générés',
            ].map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.toSurface(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.dangerous,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cette action est IRRÉVERSIBLE!',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune récupération ne sera possible.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: AppColors.getTextColor(ThemeService().isDarkMode),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Tout supprimer',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Suppression en cours...',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(ThemeService().isDarkMode),
              ),
            ),
            Text(
              'Veuillez patienter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.getTextColor(ThemeService().isDarkMode, type: TextType.secondary),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Exécuter la suppression de toutes les données
      await ref.read(adherentProvider.notifier).clearAllData();

      // Fermer le dialogue de chargement
      Navigator.pop(context);

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Toutes les données ont été supprimées avec succès!',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // Réinitialiser les animations de la liste
      _listAnimationController.reset();
      _listAnimationController.forward();

    } catch (error) {
      // Fermer le dialogue de chargement
      Navigator.pop(context);

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Row(
            children: [
              Icon(Icons.error, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erreur lors de la suppression: $error',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.upload_file,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text('Importer nouvelle liste'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cette action va:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...[
              '❌ Supprimer tous les adhérents existants',
              '✅ Importer la nouvelle liste de 39 adhérents',
              '✅ Conserver les cotisations et paiements existants',
            ].map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                item,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.toSurface(),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action est irréversible!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _importNewAdherents();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: Text('Importer'),
          ),
        ],
      ),
    );
  }

  Future<void> _importNewAdherents() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text('Importation en cours...'),
            Text(
              'Veuillez patienter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.getTextColor(ThemeService().isDarkMode, type: TextType.secondary),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Créer la liste des nouveaux adhérents à partir de la liste complète
      final newAdherents = [
        Adherent(
          nom: 'YAO',
          prenom: 'KOUASSI ETIENNE',
          telephone: '0504392510',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOFFI',
          prenom: 'YAO VALENTIN',
          telephone: '0708372926',
          montantAnnuelContribution: 60000,
        ),
        Adherent(
          nom: 'KOUAKOU',
          prenom: 'BROU DESIRE',
          telephone: '0758256724',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOUAME',
          prenom: 'ADRIEN',
          telephone: '0759329607',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOUAKOU',
          prenom: 'EUGENE',
          telephone: '0708234209',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KANGAH',
          prenom: 'KOUADIO RODRIGUE',
          telephone: '0707394444',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOFFI',
          prenom: 'YAO ALBERT',
          telephone: '0707058217',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'YAO',
          prenom: 'KOUADIO PARFAIT',
          telephone: '0748855948',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'YAO',
          prenom: 'MARCELLIN',
          telephone: '0101650936',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'YAO',
          prenom: 'KABEGE',
          telephone: '0709541039',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOUAME',
          prenom: 'KOUAKOU EDMOND',
          telephone: '0707673232',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'YAO',
          prenom: 'MATHURIN',
          telephone: '0709983874',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOUAKOU',
          prenom: 'EDMOND',
          telephone: '0748345289',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOUAKOU',
          prenom: 'N\'GUESSAN AROUINETTE',
          telephone: '',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOUADIO',
          prenom: 'KOUAKI JONAS',
          telephone: '0748804695',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOUASSI',
          prenom: 'KOUAKOU LUCIEN',
          telephone: '0759695264',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KOUASSI',
          prenom: 'KOUAME CAMILLE',
          telephone: '0747967420',
          montantAnnuelContribution: 40000,
        ),
        Adherent(
          nom: 'KOUADIO',
          prenom: 'KOUAKOU JEAN',
          telephone: '0709877128',
          montantAnnuelContribution: 30000,
        ),
        Adherent(
          nom: 'YAO',
          prenom: 'CHRISTIAN',
          telephone: '0709220365',
          montantAnnuelContribution: 30000,
        ),
        Adherent(
          nom: 'KONAN',
          prenom: 'PIERRE',
          telephone: '',
          montantAnnuelContribution: 30000,
        ),
        Adherent(
          nom: 'BROU',
          prenom: 'KOUASSI BENJAMIN',
          telephone: '0748154196',
          montantAnnuelContribution: 25000,
        ),
        Adherent(
          nom: 'N\'GUESSAN',
          prenom: 'ANNICK DIANE',
          telephone: '0727553216',
          montantAnnuelContribution: 25000,
        ),
        Adherent(
          nom: 'SHAKA',
          prenom: 'KOFFI ALEX',
          telephone: '0748201010',
          montantAnnuelContribution: 25000,
        ),
        Adherent(
          nom: 'KOFFI',
          prenom: 'KOUADIO CELESTIN',
          telephone: '0709864401',
          montantAnnuelContribution: 20000,
        ),
        Adherent(
          nom: 'KOFFI',
          prenom: 'AKISSI GEORGETTE',
          telephone: '0747506425',
          montantAnnuelContribution: 20000,
        ),
        Adherent(
          nom: 'KONAN',
          prenom: 'KOFFI FIRMIN',
          telephone: '0747737216',
          montantAnnuelContribution: 20000,
        ),
        Adherent(
          nom: 'KOUASSI',
          prenom: 'AMENAN JACQUELINE',
          telephone: '0708868157',
          montantAnnuelContribution: 20000,
        ),
        Adherent(
          nom: 'KOUADIO',
          prenom: 'ADRIEN',
          telephone: '0787309414',
          montantAnnuelContribution: 20000,
        ),
        Adherent(
          nom: 'KOFFI',
          prenom: 'YAO',
          telephone: '0708804961',
          montantAnnuelContribution: 10000,
        ),
        Adherent(
          nom: 'KANGAH',
          prenom: 'EULALIE',
          telephone: '0759976778',
          montantAnnuelContribution: 10000,
        ),
        Adherent(
          nom: 'KOFFI',
          prenom: 'N\'GOUAN CLARISSE',
          telephone: '0749660300',
          montantAnnuelContribution: 10000,
        ),
        Adherent(
          nom: 'KOUAKOU',
          prenom: 'KOUADIO ARTHUR',
          telephone: '0757259824',
          montantAnnuelContribution: 5000,
        ),
        Adherent(
          nom: 'KOUAKOU',
          prenom: 'YAO FREDERIC',
          telephone: '0768556608',
          montantAnnuelContribution: 5000,
        ),
        Adherent(
          nom: 'KOUADIO',
          prenom: 'YAO SERGE',
          telephone: '0566469740',
          montantAnnuelContribution: 5000,
        ),
        Adherent(
          nom: 'KOUADIO',
          prenom: 'BENJAMIN',
          telephone: '',
          montantAnnuelContribution: 50000,
        ),
        Adherent(
          nom: 'KONAN',
          prenom: 'AHOU JACQUELINE',
          telephone: '',
          montantAnnuelContribution: 50000,
        ),
      ];

      // Exécuter l'importation
      await ref.read(adherentProvider.notifier).resetWithNewAdherents(newAdherents);

      // Fermer le dialogue de chargement
      Navigator.pop(context);

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Succès! ${newAdherents.length} adhérents importés',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Réinitialiser les animations de la liste
      _listAnimationController.reset();
      _listAnimationController.forward();

    } catch (error) {
      // Fermer le dialogue de chargement
      Navigator.pop(context);

      // Afficher un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Row(
            children: [
              Icon(Icons.error, color: AppColors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erreur lors de l\'importation: $error',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtrer les adhérents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Tous'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _searchQuery = '');
              },
            ),
            ListTile(
              title: Text('Actifs uniquement'),
              onTap: () {
                Navigator.pop(context);
                // Implémenter le filtre
              },
            ),
            ListTile(
              title: Text('Inactifs uniquement'),
              onTap: () {
                Navigator.pop(context);
                // Implémenter le filtre
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AdherentDetailsScreen extends ConsumerStatefulWidget {
  final Adherent adherent;

  const AdherentDetailsScreen({Key? key, required this.adherent}) : super(key: key);

  @override
  ConsumerState<AdherentDetailsScreen> createState() => _AdherentDetailsScreenState();
}

class _AdherentDetailsScreenState extends ConsumerState<AdherentDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;
  final ThemeService _themeService = ThemeService();
  final Set<String> _expandedCotisations = <String>{};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _tabController = TabController(length: 4, vsync: this);
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDarkMode),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isDarkMode),
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildProfileHeader(isDarkMode),
                        _buildSummaryCards(isDarkMode),
                        _buildTabBarSection(isDarkMode),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildTabBarView(),
        ],
      ),
    );
  }

  Widget _buildTabBarSection(bool isDarkMode) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              final isSelected = _tabController.index == index;
              return GestureDetector(
                onTap: () {
                  _tabController.animateTo(index);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? AppColors.primaryGradient
                        : null,
                    color: !isSelected
                        ? AppColors.getSurfaceColor(isDarkMode)
                        : null,
                    borderRadius: BorderRadius.circular(20),
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
                        ? Border.all(
                      color: AppColors.getBorderColor(isDarkMode),
                    )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTabIcon(index),
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTabTitle(index),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.person_outline;
      case 1:
        return Icons.receipt_long;
      case 2:
        return Icons.account_balance_wallet;
      case 3:
        return Icons.history;
      default:
        return Icons.help_outline;
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Informations';
      case 1:
        return 'Cotisations';
      case 2:
        return 'Paiements';
      case 3:
        return 'Historique';
      default:
        return '';
    }
  }

  Widget _buildTabBarView() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildInformationsTab(),
          _buildCotisationsTab(),
          _buildPaiementsTab(),
          _buildHistoriqueTab(),
        ],
      ),
    );
  }

  Widget _buildInformationsTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildInformationsSection(context),
    );
  }

  Widget _buildCotisationsTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionHeader(
            '📄 Cotisations',
            Icons.receipt_long,
            AppColors.success,
            isDarkMode,
          ),
          const SizedBox(height: 16),
          _buildAdherentCotisationsList(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildAdherentCotisationsList(bool isDarkMode) {
    return Consumer(
      builder: (context, ref, child) {
        final cotisationsAsync = ref.watch(cotisationProvider);
        
        return cotisationsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(cotisationProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          data: (cotisations) {
            // Filtrer les cotisations pour cet adhérent uniquement
            final adherentCotisations = cotisations
                .where((c) => c.adherentId == widget.adherent.id)
                .toList()
              ..sort((a, b) => b.annee.compareTo(a.annee));
            
            if (adherentCotisations.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune cotisation trouvée',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cet adhérent n\'a pas encore de cotisation enregistrée',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(cotisationProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Résumé des cotisations
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.getBorderColor(isDarkMode),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${adherentCotisations.length} cotisation(s) trouvée(s)',
                          style: TextStyle(
                            color: AppColors.getTextColor(isDarkMode),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.refresh(cotisationProvider),
                        child: Text(
                          'Actualiser',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Afficher les cotisations sans cartes
                ...adherentCotisations.map((cotisation) {
                  return _buildCotisationItem(cotisation, isDarkMode);
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCotisationItem(cotisation, bool isDarkMode) {
    final estSoldee = cotisation.estSoldee;
    final statusColor = estSoldee 
        ? AppColors.success 
        : cotisation.montantPaye > 0 
            ? AppColors.warning 
            : AppColors.error;
    final isExpanded = _expandedCotisations.contains(cotisation.id);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedCotisations.remove(cotisation.id);
          } else {
            _expandedCotisations.add(cotisation.id);
          }
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.getBorderColor(isDarkMode),
          ),
        ),
        color: AppColors.getSurfaceColor(isDarkMode),
        child: Column(
          children: [
            // Main content (always visible)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.toSurface(),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Année ${cotisation.annee}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.getTextColor(isDarkMode),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cotisation.montantFormate,
                          style: TextStyle(
                            color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      cotisation.statut,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
                  ),
                ],
              ),
            ),
            
            // Expanded content (visible only when expanded)
            if (isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Payé: ${cotisation.montantPayeFormate}',
                          style: TextStyle(
                            color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/ ${cotisation.montantFormate}',
                          style: TextStyle(
                            color: AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${cotisation.pourcentagePaye.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Barre de progression
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.getBorderColor(isDarkMode),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: cotisation.pourcentagePaye / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaiementsTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionHeader(
            '💳 Historique des paiements',
            Icons.account_balance_wallet,
            AppColors.warning,
            isDarkMode,
          ),
          const SizedBox(height: 16),
          _buildAdherentPaiementsList(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildAdherentPaiementsList(bool isDarkMode) {
    return Consumer(
      builder: (context, ref, child) {
        final paiementsAsync = ref.watch(paiementProvider);
        
        return paiementsAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(paiementProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          data: (paiements) {
            // Filtrer les paiements pour cet adhérent uniquement
            final adherentPaiements = paiements
                .where((p) => p.adherentId == widget.adherent.id)
                .toList()
              ..sort((a, b) => b.datePaiement.compareTo(a.datePaiement));
            
            if (adherentPaiements.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 64,
                        color: AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun paiement trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.getTextColor(isDarkMode),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cet adhérent n\'a pas encore effectué de paiement',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Ajouter un bouton pour forcer le rechargement
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.refresh(paiementProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Ajouter un résumé des paiements
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.getBorderColor(isDarkMode),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${adherentPaiements.length} paiement(s) trouvé(s)',
                          style: TextStyle(
                            color: AppColors.getTextColor(isDarkMode),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.refresh(paiementProvider),
                        child: Text(
                          'Actualiser',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Afficher les paiements
                ...adherentPaiements.map((paiement) {
                  return _buildPaiementCard(paiement, isDarkMode);
                }).toList(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPaiementCard(Paiement paiement, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(isDarkMode),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? AppColors.black.withOpacity(0.02)
                : AppColors.black.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.toSurface(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Année ${paiement.annee}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.getTextColor(isDarkMode),
                            ),
                          ),
                          Text(
                            widget.adherent.nomComplet,
                            style: TextStyle(
                              color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        paiement.montantFormate,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.info.toSurface(),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(paiement.datePaiement),
                      style: TextStyle(
                        color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.toSurface(),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.payment,
                        size: 14,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      paiement.methodeFormate,
                      style: TextStyle(
                        color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (paiement.notes != null && paiement.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode 
                          ? AppColors.white.withOpacity(0.05)
                          : AppColors.grey50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.getBorderColor(isDarkMode).withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            paiement.notes!,
                            style: TextStyle(
                              color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoriqueTab() {
    final isDarkMode = _themeService.isDarkMode;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionHeader(
            '📈 Historique des activités',
            Icons.history,
            AppColors.info,
            isDarkMode,
          ),
          const SizedBox(height: 16),
          _buildHistoriqueItems(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getBorderColor(isDarkMode),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? AppColors.black.withOpacity(0.02)
                : AppColors.black.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.toSurface(),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextColor(isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriqueItems(bool isDarkMode) {
    final historiqueItems = [
      {
        'date': '15 Janvier 2024',
        'action': 'Paiement cotisation',
        'description': 'Cotisation annuelle 2024',
        'amount': '50 000 FCFA',
        'color': AppColors.success,
      },
      {
        'date': '10 Janvier 2024',
        'action': 'Mise à jour profil',
        'description': 'Modification des informations personnelles',
        'amount': '',
        'color': AppColors.info,
      },
      {
        'date': '20 Décembre 2023',
        'action': 'Paiement cotisation',
        'description': 'Cotisation annuelle 2023',
        'amount': '50 000 FCFA',
        'color': AppColors.success,
      },
      {
        'date': '15 Novembre 2023',
        'action': 'Inscription',
        'description': 'Nouvel adhérent',
        'amount': '',
        'color': AppColors.primary,
      },
    ];

    return Column(
      children: historiqueItems.map((item) {
        final color = item['color'] as Color;
        final action = item['action'] as String;
        final description = item['description'] as String;
        final date = item['date'] as String;
        final amount = item['amount'] as String;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(isDarkMode),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.getBorderColor(isDarkMode),
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode 
                    ? AppColors.black.withOpacity(0.1)
                    : AppColors.shadowLight.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.history,
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
                      action,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextColor(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (amount.isNotEmpty)
                Text(
                  amount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliverAppBar(bool isDarkMode) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.getPureAppBarBackground(isDarkMode),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.adherent.nomComplet,
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.edit, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () {
            // TODO: Implémenter l'édition
          },
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          onPressed: () {
            // TODO: Menu options
          },
        ),
      ],
    );
  }
  Widget _buildProfileHeader(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: AppColors.white,
                  child: widget.adherent.photoUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.adherent.photoUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          ),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.adherent.nomComplet,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.adherent.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusBadge(
                          widget.adherent.estActif ? '✓ Actif' : '✗ Inactif',
                          widget.adherent.estActif ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(
                          'Membre',
                          AppColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person,
      size: 40,
      color: AppColors.primary,
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Cotisations', 
                  '${math.Random().nextInt(50) + 10}',
                  AppColors.success, 
                  Icons.receipt_long,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Montant Total', 
                  '${(math.Random().nextInt(500) + 100)}000 FCFA',
                  AppColors.primary, 
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Dernier Paiement', 
                  'Il y a ${math.Random().nextInt(30) + 1} jours',
                  AppColors.warning, 
                  Icons.history,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Statut', 
                  widget.adherent.estActif ? 'Actif' : 'Inactif',
                  widget.adherent.estActif ? AppColors.success : AppColors.error, 
                  widget.adherent.estActif ? Icons.check_circle : Icons.cancel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(isDarkMode),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? AppColors.black.withOpacity(0.02)
                : AppColors.black.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.toSurface(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationsSection(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getBorderColor(isDarkMode),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? AppColors.black.withOpacity(0.02)
                : AppColors.black.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.toSurface(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Informations Personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          
          // Information Fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildInfoRow('Téléphone', widget.adherent.telephone, isDarkMode),
                const SizedBox(height: 16),
                _buildInfoRow('Email', widget.adherent.email, isDarkMode),
                const SizedBox(height: 16),
                _buildInfoRow('Adresse', widget.adherent.adresse, isDarkMode),
                const SizedBox(height: 16),
                _buildInfoRow(
                  'Date d\'adhésion',
                  DateFormat('dd MMMM yyyy').format(widget.adherent.dateAdhesion),
                  isDarkMode,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'Non renseigné',
            style: TextStyle(
              color: value.isNotEmpty 
                  ? AppColors.getTextColor(isDarkMode)
                  : AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildPaiementsSection(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDarkMode),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.getBorderColor(isDarkMode),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
                ? AppColors.black.withOpacity(0.02)
                : AppColors.black.withOpacity(0.08),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.toSurface(),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Paiements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildPaiementItem('15 Janvier 2024', '50 000 FCFA', 'Cotisation 2024', AppColors.success, isDarkMode),
                const SizedBox(height: 12),
                _buildPaiementItem('20 Décembre 2023', '50 000 FCFA', 'Cotisation 2023', AppColors.success, isDarkMode),
                const SizedBox(height: 12),
                _buildPaiementItem('18 Novembre 2022', '45 000 FCFA', 'Cotisation 2022', AppColors.success, isDarkMode),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaiementItem(String date, String amount, String description, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.white.withOpacity(0.05) : AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(isDarkMode).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.toSurface(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payment,
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
                  description,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AdherentFormScreen extends ConsumerStatefulWidget {
  final Adherent? adherent;

  const AdherentFormScreen({Key? key, this.adherent}) : super(key: key);

  @override
  ConsumerState<AdherentFormScreen> createState() => _AdherentFormScreenState();
}

class _AdherentFormScreenState extends ConsumerState<AdherentFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _contributionController = TextEditingController();
  DateTime? _dateAdhesion;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ThemeService _themeService = ThemeService();
  final Map<String, bool> _fieldFocused = {
    'nom': false,
    'prenom': false,
    'telephone': false,
    'email': false,
    'adresse': false,
    'contribution': false,
  };

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
    
    if (widget.adherent != null) {
      _nomController.text = widget.adherent!.nom;
      _prenomController.text = widget.adherent!.prenom;
      _telephoneController.text = widget.adherent!.telephone;
      _emailController.text = widget.adherent!.email;
      _adresseController.text = widget.adherent!.adresse;
      _contributionController.text = widget.adherent!.montantAnnuelContribution.toString();
      _dateAdhesion = widget.adherent!.dateAdhesion;
    } else {
      _dateAdhesion = DateTime.now();
      _contributionController.text = '12000';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _contributionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _themeService.isDarkMode;
    
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildDragHandle(),
                  _buildHeader(isDarkMode),
                  Expanded(
                    child: _buildFormContent(isDarkMode),
                  ),
                  _buildActions(isDarkMode),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.adherent == null ? Icons.person_add : Icons.edit,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.adherent == null ? 'Nouvel Adhérent' : 'Modifier l\'Adhérent',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.adherent == null 
                      ? 'Remplissez les informations pour ajouter un nouvel adhérent'
                      : 'Modifiez les informations de l\'adhérent',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildAnimatedField(
              isDarkMode,
              controller: _nomController,
              label: 'Nom',
              icon: Icons.person,
              isRequired: true,
              fieldKey: 'nom',
              keyboardType: TextInputType.name,
              validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: 12),
            _buildAnimatedField(
              isDarkMode,
              controller: _prenomController,
              label: 'Prénom',
              icon: Icons.person_outline,
              isRequired: true,
              fieldKey: 'prenom',
              keyboardType: TextInputType.name,
              validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: 12),
            _buildAnimatedField(
              isDarkMode,
              controller: _telephoneController,
              label: 'Téléphone',
              icon: Icons.phone,
              isRequired: true,
              fieldKey: 'telephone',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty == true) return 'Champ obligatoire';
                if (value!.length < 8) return 'Numéro invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildAnimatedField(
              isDarkMode,
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              isRequired: false,
              fieldKey: 'email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildAnimatedField(
              isDarkMode,
              controller: _adresseController,
              label: 'Adresse',
              icon: Icons.location_on,
              isRequired: false,
              fieldKey: 'adresse',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _buildAnimatedField(
              isDarkMode,
              controller: _contributionController,
              label: 'Contribution annuelle (FCFA)',
              icon: Icons.money,
              isRequired: true,
              fieldKey: 'contribution',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Champ obligatoire';
                final montant = int.tryParse(value!);
                if (montant == null) return 'Montant invalide';
                if (montant < 1000) return 'Le montant minimum est de 1000 FCFA';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildDateField(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedField(
    bool isDarkMode, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isRequired,
    required String fieldKey,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isFocused = _fieldFocused[fieldKey] ?? false;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused 
              ? AppColors.primary 
              : Colors.grey.shade300,
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          labelStyle: TextStyle(
            color: isFocused 
                ? AppColors.primary 
                : Colors.grey.shade600,
            fontSize: 12,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isFocused 
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isFocused 
                  ? AppColors.primary 
                  : Colors.grey.shade600,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onTap: () => setState(() => _fieldFocused[fieldKey] = true),
        onTapOutside: (_) => setState(() => _fieldFocused[fieldKey] = false),
        onEditingComplete: () => setState(() => _fieldFocused[fieldKey] = false),
      ),
    );
  }

  Widget _buildDateField(bool isDarkMode) {
    return GestureDetector(
      onTap: _selectDate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.calendar_today,
                size: 18,
                color: AppColors.info,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date d\'adhésion *',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMMM yyyy').format(_dateAdhesion!),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade600,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
              child: Text(
                AppStrings.annuler,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAdherent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Enregistrement...', style: TextStyle(fontSize: 14)),
                      ],
                    )
                  : const Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveAdherent() {
    if (_formKey.currentState?.validate() == true) {
      setState(() {
        _isLoading = true;
      });
      
      // Simuler un délai pour montrer l'animation de chargement
      Future.delayed(const Duration(milliseconds: 500), () {
        final adherent = Adherent(
          id: widget.adherent?.id,
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          email: _emailController.text.trim(),
          adresse: _adresseController.text.trim(),
          dateAdhesion: _dateAdhesion ?? DateTime.now(),
          montantAnnuelContribution: int.parse(_contributionController.text),
          estActif: widget.adherent?.estActif ?? true,
        );

        if (widget.adherent == null) {
          ref.read(adherentProvider.notifier).addAdherent(adherent);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Adhérent ajouté avec succès!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ref.read(adherentProvider.notifier).updateAdherent(adherent);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Adhérent modifié avec succès!'),
                ],
              ),
              backgroundColor: AppColors.info,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        Navigator.pop(context);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateAdhesion ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _dateAdhesion) {
      setState(() {
        _dateAdhesion = picked;
      });
    }
  }
}