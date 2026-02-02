import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cotisation_provider.dart';
import '../providers/adherent_provider.dart';
import '../providers/paiement_provider.dart';
import '../models/cotisation.dart';
import '../models/adherent.dart';
import '../models/paiement.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../config/app_colors.dart';
import '../services/theme_service.dart';
import '../widgets/searchable_adherent_dropdown.dart';

class CotisationsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CotisationsScreen> createState() => _CotisationsScreenState();
}

class _CotisationsScreenState extends ConsumerState<CotisationsScreen> {
  int anneeSelectionnee = DateTime.now().year;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _expandedCardKey;
  final ThemeService _themeService = ThemeService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cotisationsAsync = ref.watch(cotisationProvider);
    final adherentsAsync = ref.watch(adherentProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: cotisationsAsync.when(
              loading: () => LoadingWidget(),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Erreur: $error'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(cotisationProvider.notifier).loadCotisations(),
                      child: Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (cotisations) => adherentsAsync.when(
                loading: () => LoadingWidget(),
                error: (error, stack) => Center(child: Text('Erreur: $error')),
                data: (adherents) => _buildCotisationsList(cotisations, adherents),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "btn1",
            onPressed: _showAddCotisationDialog,
            child: Icon(Icons.person_add),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tooltip: 'Ajouter une cotisation individuelle',
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "btn2",
            onPressed: _showAddGlobalCotisationDialog,
            child: Icon(Icons.group_add),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tooltip: 'Ajouter des cotisations globales',
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Année en cours',
                style: TextStyle(
                  color: AppColors.getTextColor(_themeService.isDarkMode, type: TextType.secondary),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '$anneeSelectionnee',
                style: TextStyle(
                  color: AppColors.getTextColor(_themeService.isDarkMode),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(_themeService.isDarkMode),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.getBorderColor(_themeService.isDarkMode),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: 16, color: AppColors.getTextColor(_themeService.isDarkMode)),
                  onPressed: () => setState(() => anneeSelectionnee--),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
              SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(_themeService.isDarkMode),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.getBorderColor(_themeService.isDarkMode),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.getTextColor(_themeService.isDarkMode)),
                  onPressed: () => setState(() => anneeSelectionnee++),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher une cotisation...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
              : null,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildCotisationsList(List<Cotisation> cotisations, List<Adherent> adherents) {
    // Filtrer par année
    List<Cotisation> cotisationsAnnee = cotisations
        .where((c) => c.annee == anneeSelectionnee)
        .toList();

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      cotisationsAnnee = cotisationsAnnee.where((cotisation) {
        final adherent = adherents.firstWhere(
              (a) => a.id == cotisation.adherentId,
          orElse: () => Adherent(nom: '', prenom: '', telephone: ''),
        );
        return adherent.nom.toLowerCase().contains(lowerQuery) ||
            adherent.prenom.toLowerCase().contains(lowerQuery) ||
            cotisation.montantAnnuel.toString().contains(_searchQuery);
      }).toList();
    }

    if (cotisationsAnnee.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.money_off,
        title: 'Aucune cotisation',
        subtitle: _searchQuery.isEmpty
            ? 'Aucune cotisation pour $anneeSelectionnee'
            : 'Aucun résultat pour cette recherche',
        action: FloatingActionButton(
          onPressed: _showAddCotisationDialog,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.add),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(cotisationProvider.notifier).loadCotisations(),
      child: ListView.builder(
        itemCount: cotisationsAnnee.length,
        itemBuilder: (context, index) {
          final cotisation = cotisationsAnnee[index];
          final adherent = adherents.firstWhere(
                (a) => a.id == cotisation.adherentId,
            orElse: () => Adherent(nom: 'Inconnu', prenom: '', telephone: ''),
          );
          return _buildCotisationCard(cotisation, adherent);
        },
      ),
    );
  }

  Widget _buildCotisationCard(Cotisation cotisation, Adherent adherent) {
    final cardKey = cotisation.id; // Utiliser l'ID unique de la cotisation
    final isExpanded = _expandedCardKey == cardKey;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            cotisation.estSoldee 
                ? Colors.green.withOpacity(0.02)
                : cotisation.montantPaye > 0 
                    ? Colors.orange.withOpacity(0.02)
                    : Colors.red.withOpacity(0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isExpanded ? 12 : 6,
            offset: Offset(0, isExpanded ? 6 : 3),
          ),
        ],
        border: Border.all(
          color: cotisation.estSoldee 
              ? Colors.green.withOpacity(0.2)
              : cotisation.montantPaye > 0 
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleCardExpansion(cardKey),
          child: Padding(
            padding: EdgeInsets.all(isExpanded ? 16 : 12),
            child: Column(
              children: [
                _buildCardHeader(cotisation, adherent, isExpanded),
                SizedBox(height: isExpanded ? 12 : 8),
                _buildCardProgress(cotisation, isExpanded),
                if (isExpanded) ...[
                  SizedBox(height: 16),
                  _buildCardActions(cotisation, adherent),
                ] else ...[
                  SizedBox(height: 6),
                  _buildCompactActions(cotisation, adherent),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCardExpansion(String cardKey) {
    setState(() {
      if (_expandedCardKey == cardKey) {
        _expandedCardKey = null; // Fermer la carte actuelle
      } else {
        _expandedCardKey = cardKey; // Ouvrir la nouvelle carte (fermer automatiquement l'ancienne)
      }
    });
  }

  Widget _buildCardHeader(Cotisation cotisation, Adherent adherent, bool isExpanded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cotisation.estSoldee 
                        ? Colors.green.withOpacity(0.15)
                        : cotisation.montantPaye > 0 
                            ? Colors.orange.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                    cotisation.estSoldee 
                        ? Colors.green.withOpacity(0.05)
                        : cotisation.montantPaye > 0 
                            ? Colors.orange.withOpacity(0.05)
                            : Colors.red.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(
                cotisation.estSoldee 
                    ? Icons.check_circle 
                    : cotisation.montantPaye > 0 
                        ? Icons.pending
                        : Icons.money_off,
                color: cotisation.estSoldee 
                    ? Colors.green.shade600
                    : cotisation.montantPaye > 0 
                        ? Colors.orange.shade600
                    : Colors.red.shade600,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adherent.nomComplet,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  // Badge de statut et année sur la même ligne
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: cotisation.estSoldee 
                              ? Colors.green.withOpacity(0.06)
                              : cotisation.montantPaye > 0 
                                  ? Colors.orange.withOpacity(0.06)
                                  : Colors.red.withOpacity(0.06),
                        ),
                        child: Text(
                          cotisation.statut,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            color: cotisation.estSoldee 
                                ? Colors.green.shade600
                                : cotisation.montantPaye > 0 
                                    ? Colors.orange.shade600
                                    : Colors.red.shade600,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '• ${cotisation.annee}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        // Afficher la progression uniquement quand le card est étendu
        if (isExpanded) ...[
          SizedBox(height: 8),
          Row(
            children: [
              SizedBox(width: 48), // Aligner avec l'icône
              Spacer(),
              if (cotisation.pourcentagePaye > 0) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cotisation.estSoldee 
                        ? Colors.green.withOpacity(0.1)
                        : cotisation.montantPaye > 0 
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                  ),
                  child: Text(
                    '${cotisation.pourcentagePaye.toStringAsFixed(1)}% payé',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cotisation.estSoldee 
                          ? Colors.green.shade700
                          : cotisation.montantPaye > 0 
                              ? Colors.orange.shade700
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCardProgress(Cotisation cotisation, bool isExpanded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Afficher les montants dans tous les cas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: isExpanded ? 11 : 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  cotisation.montantFormate,
                  style: TextStyle(
                    fontSize: isExpanded ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Payé',
                  style: TextStyle(
                    fontSize: isExpanded ? 11 : 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  cotisation.montantPayeFormate,
                  style: TextStyle(
                    fontSize: isExpanded ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: cotisation.montantPaye > 0 ? Colors.green.shade600 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Reste',
                  style: TextStyle(
                    fontSize: isExpanded ? 11 : 10,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  cotisation.resteFormate,
                  style: TextStyle(
                    fontSize: isExpanded ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: cotisation.resteAPayer > 0 ? Colors.red.shade600 : Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Afficher la progression complète uniquement quand le card est étendu
        if (isExpanded) ...[
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression du paiement',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${cotisation.pourcentagePaye.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cotisation.estSoldee 
                      ? Colors.green.shade600
                      : cotisation.montantPaye > 0 
                          ? Colors.orange.shade600
                          : Colors.red.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade200,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: cotisation.pourcentagePaye / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      cotisation.estSoldee 
                          ? Colors.green.shade400
                          : cotisation.montantPaye > 0 
                              ? Colors.orange.shade400
                              : Colors.red.shade400,
                      cotisation.estSoldee 
                          ? Colors.green.shade600
                          : cotisation.montantPaye > 0 
                              ? Colors.orange.shade600
                              : Colors.red.shade600,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          // Version compacte de la barre de progression pour card fermé
          SizedBox(height: 6),
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              color: Colors.grey.shade200,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: cotisation.pourcentagePaye / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  gradient: LinearGradient(
                    colors: [
                      cotisation.estSoldee 
                          ? Colors.green.shade400
                          : cotisation.montantPaye > 0 
                              ? Colors.orange.shade400
                              : Colors.red.shade400,
                      cotisation.estSoldee 
                          ? Colors.green.shade600
                          : cotisation.montantPaye > 0 
                              ? Colors.orange.shade600
                              : Colors.red.shade600,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  Widget _buildCardActions(Cotisation cotisation, Adherent adherent) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showEditCotisationDialog(cotisation, adherent),
            icon: Icon(Icons.edit, size: 14),
            label: Text('Modifier'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              side: BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              minimumSize: Size(0, 32),
              textStyle: TextStyle(fontSize: 12),
            ),
          ),
        ),
        SizedBox(width: 6),
        if (!cotisation.estSoldee)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showPaymentDialog(cotisation, adherent),
              icon: Icon(Icons.payment, size: 14),
              label: Text('Payé'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7B1FA2), // Violet-rougeâtre harmonieux
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                minimumSize: Size(0, 32),
                textStyle: TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (!cotisation.estSoldee) SizedBox(width: 6),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteConfirmation(cotisation, adherent),
            icon: Icon(Icons.delete, size: 14),
            label: Text('Supprimer'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              side: BorderSide(color: Colors.red),
              foregroundColor: Colors.red,
              minimumSize: Size(0, 32),
              textStyle: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActions(Cotisation cotisation, Adherent adherent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!cotisation.estSoldee)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF7B1FA2).withOpacity(0.8)],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _showPaymentDialog(cotisation, adherent),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payment,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Payé',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showDeleteConfirmation(Cotisation cotisation, Adherent adherent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: Colors.orange,
              size: 24,
            ),
            SizedBox(width: 12),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir supprimer cette cotisation ?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détails de la cotisation :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Adhérent: ${adherent.nomComplet}'),
                  Text('Année: ${cotisation.annee}'),
                  Text('Montant: ${cotisation.montantFormate}'),
                  Text('Payé: ${cotisation.montantPayeFormate}'),
                  Text('Statut: ${cotisation.statut}'),
                ],
              ),
            ),
            if (cotisation.montantPaye > 0) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attention: Cette cotisation a déjà des paiements enregistrés.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteCotisation(cotisation);
            },
            icon: Icon(Icons.delete, size: 16),
            label: Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteCotisation(Cotisation cotisation) {
    ref.read(cotisationProvider.notifier).deleteCotisation(cotisation.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Cotisation supprimée avec succès!'),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showPaymentDialog(Cotisation cotisation, Adherent adherent) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(cotisation: cotisation, adherent: adherent),
    ).then((_) {
      // Forcer le rechargement de tous les providers concernés
      ref.read(cotisationProvider.notifier).loadCotisations();
      ref.read(paiementProvider.notifier).loadPaiements();
    });
  }

  void _showAddGlobalCotisationDialog() {
    showDialog(
      context: context,
      builder: (context) => GlobalCotisationDialog(anneeActuelle: anneeSelectionnee),
    ).then((_) {
      ref.read(cotisationProvider.notifier).loadCotisations();
    });
  }

  void _showAddCotisationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CotisationFormScreen(),
    ).then((_) {
      ref.read(cotisationProvider.notifier).loadCotisations();
    });
  }

  void _showEditCotisationDialog(Cotisation cotisation, Adherent adherent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CotisationFormScreen(
        cotisation: cotisation,
        adherent: adherent,
      ),
    ).then((_) {
      ref.read(cotisationProvider.notifier).loadCotisations();
    });
  }
}

class CotisationFormScreen extends ConsumerStatefulWidget {
  final Cotisation? cotisation;
  final Adherent? adherent;

  const CotisationFormScreen({Key? key, this.cotisation, this.adherent}) : super(key: key);

  @override
  ConsumerState<CotisationFormScreen> createState() => _CotisationFormScreenState();
}

class _CotisationFormScreenState extends ConsumerState<CotisationFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _anneeController = TextEditingController();
  final _motifController = TextEditingController();
  final _montantController = TextEditingController();
  
  Adherent? _selectedAdherent;
  List<Adherent> _adherents = [];
  int _montantAnnuel = 0;
  bool _isLoading = false;
  Cotisation? _cotisationExistante;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ThemeService _themeService = ThemeService();
  final Map<String, bool> _fieldFocused = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
    
    _loadAdherents();
    
    if (widget.cotisation != null) {
      _anneeController.text = widget.cotisation!.annee.toString();
      _motifController.text = widget.cotisation!.motifModification ?? '';
      _montantController.text = widget.cotisation!.montantAnnuel.toString();
      _montantAnnuel = widget.cotisation!.montantAnnuel;
      _selectedAdherent = widget.adherent;
    } else {
      _anneeController.text = DateTime.now().year.toString();
      _motifController.text = 'Création de cotisation pour l\'année ${DateTime.now().year}';
      _selectedAdherent = widget.adherent;
      if (_selectedAdherent != null) {
        _montantAnnuel = _selectedAdherent!.montantAnnuelContribution;
        _montantController.text = _montantAnnuel.toString();
      }
    }
  }

  Future<void> _loadAdherents() async {
    final adherentsAsync = ref.read(adherentProvider);
    if (adherentsAsync.hasValue) {
      setState(() {
        _adherents = adherentsAsync.value!;
        if (_selectedAdherent == null && _adherents.isNotEmpty) {
          _selectedAdherent = _adherents.first;
          _montantAnnuel = _selectedAdherent!.montantAnnuelContribution;
          _montantController.text = _montantAnnuel.toString();
        }
      });
      // Vérifier la cotisation existante après le chargement
      await _verifierCotisationExistante();
    }
  }

  Future<void> _verifierCotisationExistante() async {
    if (_selectedAdherent != null && _anneeController.text.isNotEmpty) {
      try {
        final annee = int.tryParse(_anneeController.text);
        if (annee != null) {
          final cotisation = await ref.read(cotisationProvider.notifier)
              .getCotisationByAdherentAnnee(_selectedAdherent!.id, annee);
          setState(() {
            _cotisationExistante = cotisation;
          });
        }
      } catch (e) {
        setState(() {
          _cotisationExistante = null;
        });
      }
    } else {
      setState(() {
        _cotisationExistante = null;
      });
    }
  }

  @override
  void dispose() {
    _anneeController.dispose();
    _motifController.dispose();
    _montantController.dispose();
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
              widget.cotisation == null ? Icons.money : Icons.edit,
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
                  widget.cotisation == null ? 'Nouvelle Cotisation' : 'Modifier la Cotisation',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.cotisation == null 
                      ? 'Enregistrez une nouvelle cotisation pour un adhérent'
                      : 'Modifiez les informations de la cotisation',
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
            if (widget.adherent == null) ...[
              SearchableAdherentDropdown(
                label: 'Adhérent',
                selectedAdherent: _selectedAdherent,
                adherents: _adherents,
                isRequired: true,
                onChanged: (Adherent? value) {
                  setState(() {
                    _selectedAdherent = value;
                    if (value != null) {
                      _montantAnnuel = value.montantAnnuelContribution;
                      _montantController.text = _montantAnnuel.toString();
                    }
                  });
                  // Vérifier la cotisation existante après le changement d'adhérent
                  _verifierCotisationExistante();
                },
                validator: (value) => value == null ? 'Veuillez sélectionner un adhérent' : null,
              ),
              const SizedBox(height: 12),
            ] else ...[
              _buildAdherentInfo(isDarkMode),
              const SizedBox(height: 12),
            ],
            
            _buildAnimatedField(
              isDarkMode,
              controller: _anneeController,
              label: 'Année',
              icon: Icons.calendar_today,
              isRequired: true,
              fieldKey: 'annee',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Champ obligatoire';
                final annee = int.tryParse(value!);
                if (annee == null) return 'Année invalide';
                if (annee < 2000 || annee > DateTime.now().year + 1) {
                  return 'Année non valide';
                }
                return null;
              },
              onChanged: (value) {
                // Vérifier la cotisation existante après le changement d'année
                _verifierCotisationExistante();
                
                // Mettre à jour le motif par défaut si l'utilisateur ne l'a pas modifié
                if (widget.cotisation == null && 
                    (_motifController.text.isEmpty || 
                     _motifController.text.contains('Création de cotisation pour l\'année'))) {
                  final annee = int.tryParse(value);
                  if (annee != null) {
                    _motifController.text = 'Création de cotisation pour l\'année $annee';
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            
            _buildAnimatedField(
              isDarkMode,
              controller: _montantController,
              label: 'Montant annuel (FCFA)',
              icon: Icons.money,
              isRequired: true,
              fieldKey: 'montant',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Champ obligatoire';
                final montant = int.tryParse(value!);
                if (montant == null) return 'Montant invalide';
                if (montant <= 0) return 'Le montant doit être positif';
                return null;
              },
              onChanged: (value) {
                final montant = int.tryParse(value);
                if (montant != null && montant > 0) {
                  setState(() {
                    _montantAnnuel = montant;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Alert si une cotisation existe déjà
            if (_cotisationExistante != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cotisation existante',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Une cotisation de ${_cotisationExistante!.montantFormate} existe déjà pour ${_selectedAdherent?.nomComplet ?? 'cet adhérent'} en ${_cotisationExistante!.annee}.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade600,
                            ),
                          ),
                          if (_cotisationExistante!.montantPaye > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Montant déjà payé: ${_cotisationExistante!.montantPayeFormate}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            _buildAnimatedField(
              isDarkMode,
              controller: _motifController,
              label: widget.cotisation == null ? 'Motif de création' : 'Motif de modification',
              icon: Icons.edit_note,
              isRequired: widget.cotisation == null,
              fieldKey: 'motif',
              maxLines: 3,
              validator: (value) {
                if (widget.cotisation == null && (value?.isEmpty == true || value?.trim() == '')) {
                  return 'Le motif est obligatoire pour la création';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherentInfo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.person,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adhérent',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  widget.adherent!.nomComplet,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    Function(String)? onChanged,
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
        onChanged: onChanged,
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
              onPressed: (_isLoading || (_cotisationExistante != null && widget.cotisation == null)) ? null : _saveCotisation,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cotisationExistante != null && widget.cotisation == null 
                    ? Colors.grey.shade400 
                    : AppColors.primary,
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
                  : Text(
                      _cotisationExistante != null && widget.cotisation == null 
                          ? 'Cotisation existante'
                          : (widget.cotisation == null ? 'Enregistrer' : 'Modifier'),
                      style: const TextStyle(
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

  void _saveCotisation() async {
    if (_formKey.currentState?.validate() == true && _selectedAdherent != null) {
      setState(() => _isLoading = true);
      
      final adherentId = _selectedAdherent!.id;
      final annee = int.parse(_anneeController.text);
      final montantAnnuel = int.parse(_montantController.text);
      final motif = _motifController.text.trim();

      try {
        if (widget.cotisation == null) {
          // Vérifier si une cotisation existe déjà pour cet adhérent et cette année
          final cotisationExistante = await ref.read(cotisationProvider.notifier)
              .getCotisationByAdherentAnnee(adherentId, annee);
          
          if (cotisationExistante != null) {
            throw Exception('Une cotisation existe déjà pour cet adhérent pour l\'année $annee');
          }

          // Nouvelle cotisation
          final cotisation = Cotisation(
            adherentId: adherentId,
            montantAnnuel: montantAnnuel,
            montantPaye: 0, // Initialement rien n'est payé
            annee: annee,
            motifModification: motif.isEmpty ? 'Création de cotisation' : motif,
          );

          ref.read(cotisationProvider.notifier).addCotisation(cotisation);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Cotisation créée avec succès!'),
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
          // Modification de cotisation
          final cotisation = widget.cotisation!.copyWith(
            montantAnnuel: montantAnnuel,
            annee: annee,
            dateModification: DateTime.now(),
            motifModification: motif.isEmpty 
                ? 'Modification de cotisation' 
                : motif,
          );

          ref.read(cotisationProvider.notifier).updateCotisation(cotisation);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Cotisation modifiée avec succès!'),
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Erreur: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

class PaymentDialog extends ConsumerStatefulWidget {
  final Cotisation cotisation;
  final Adherent adherent;

  const PaymentDialog({Key? key, required this.cotisation, required this.adherent}) : super(key: key);

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _notesController = TextEditingController();
  String _methodePaiement = 'Espèce';

  @override
  void dispose() {
    _montantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Effectuer un paiement'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Adhérent: ${widget.adherent.nomComplet}'),
                Text('Année: ${widget.cotisation.annee}'),
                Text('Contribution: ${widget.cotisation.montantFormate}'),
                Text('Déjà payé: ${widget.cotisation.montantPayeFormate}'),
                Text(
                  'Reste à payer: ${widget.cotisation.resteFormate}',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                
                DropdownButtonFormField<String>(
                  value: _methodePaiement,
                  decoration: InputDecoration(
                    labelText: 'Méthode de paiement',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: [
                    DropdownMenuItem(value: 'Espèce', child: Text('Espèce')),
                    DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                    DropdownMenuItem(value: 'Virement', child: Text('Virement')),
                    DropdownMenuItem(value: 'Chèque', child: Text('Chèque')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _methodePaiement = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: _montantController,
                  decoration: InputDecoration(
                    labelText: 'Montant à payer (FCFA) *',
                    prefixIcon: Icon(Icons.money),
                    hintText: 'Maximum: ${widget.cotisation.resteFormate}',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Champ obligatoire';
                    final montant = int.tryParse(value!);
                    if (montant == null) return 'Montant invalide';
                    if (montant <= 0) return 'Le montant doit être positif';
                    if (montant > widget.cotisation.resteAPayer) {
                      return 'Le montant ne peut pas dépasser le reste à payer';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optionnel)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _processPayment,
          child: Text('Payer'),
        ),
      ],
    );
  }

  void _processPayment() {
    if (_formKey.currentState?.validate() == true) {
      final montant = int.parse(_montantController.text);
      final nouveauMontantPaye = widget.cotisation.montantPaye + montant;
      
      // 1. Créer l'enregistrement de paiement
      final paiement = Paiement(
        adherentId: widget.adherent.id,
        annee: widget.cotisation.annee,
        montantVerse: montant,
        datePaiement: DateTime.now(),
        statut: StatutPaiement.complete,
        methode: _convertMethodePaiement(_methodePaiement),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // 2. Ajouter le paiement (notifie paiementProvider)
      ref.read(paiementProvider.notifier).addPaiement(paiement);
      
      // 3. Mettre à jour la cotisation (notifie cotisationProvider)
      final cotisationMaj = widget.cotisation.copyWith(
        montantPaye: nouveauMontantPaye,
        dateModification: DateTime.now(),
        motifModification: 'Paiement de $montant FCFA par $_methodePaiement${_notesController.text.isNotEmpty ? ' - ${_notesController.text}' : ''}',
      );

      ref.read(cotisationProvider.notifier).updateCotisation(cotisationMaj);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement de $montant FCFA enregistré avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  MethodePaiement _convertMethodePaiement(String methode) {
    switch (methode) {
      case 'Espèce':
        return MethodePaiement.espece;
      case 'Mobile Money':
        return MethodePaiement.mobileMoney;
      case 'Virement':
        return MethodePaiement.virement;
      case 'Chèque':
        return MethodePaiement.cheque;
      default:
        return MethodePaiement.espece;
    }
  }
}

class GlobalCotisationDialog extends ConsumerStatefulWidget {
  final int anneeActuelle;

  const GlobalCotisationDialog({Key? key, required this.anneeActuelle}) : super(key: key);

  @override
  ConsumerState<GlobalCotisationDialog> createState() => _GlobalCotisationDialogState();
}

class _GlobalCotisationDialogState extends ConsumerState<GlobalCotisationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _anneeController = TextEditingController();
  final _montantController = TextEditingController();
  bool _useCustomAmount = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _anneeController.text = widget.anneeActuelle.toString();
  }

  @override
  void dispose() {
    _anneeController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.group_add, color: AppColors.primary),
          SizedBox(width: 12),
          Text('Ajout Global de Cotisations'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cette fonctionnalité va créer une cotisation pour tous les adhérents qui n\'en ont pas encore pour l\'année spécifiée.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _anneeController,
              decoration: InputDecoration(
                labelText: 'Année',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty == true) return 'Champ obligatoire';
                final annee = int.tryParse(value!);
                if (annee == null) return 'Année invalide';
                if (annee < 2000 || annee > 2100) return 'Année hors plage valide';
                return null;
              },
            ),
            SizedBox(height: 16),
            CheckboxListTile(
              title: Text('Utiliser un montant personnalisé'),
              subtitle: Text('Sinon, le montant par défaut de chaque adhérent sera utilisé'),
              value: _useCustomAmount,
              onChanged: (value) {
                setState(() {
                  _useCustomAmount = value!;
                  if (!value) {
                    _montantController.clear();
                  }
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_useCustomAmount) ...[
              SizedBox(height: 8),
              TextFormField(
                controller: _montantController,
                decoration: InputDecoration(
                  labelText: 'Montant personnalisé (FCFA)',
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_useCustomAmount && (value?.isEmpty == true)) {
                    return 'Champ obligatoire';
                  }
                  if (value?.isNotEmpty == true) {
                    final montant = int.tryParse(value!);
                    if (montant == null) return 'Montant invalide';
                    if (montant <= 0) return 'Le montant doit être positif';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createGlobalCotisations,
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Créer les cotisations'),
        ),
      ],
    );
  }

  void _createGlobalCotisations() async {
    if (_formKey.currentState?.validate() == true) {
      setState(() => _isLoading = true);

      try {
        final annee = int.parse(_anneeController.text);
        final montantPersonnalise = _useCustomAmount && _montantController.text.isNotEmpty
            ? int.parse(_montantController.text)
            : null;

        await ref.read(cotisationProvider.notifier).ajouterCotisationGlobale(
          annee,
          montantPersonnalise: montantPersonnalise,
        );

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Cotisations globales créées avec succès!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Text('Erreur: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
