import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/paiement_provider.dart';
import '../providers/adherent_provider.dart';
import '../models/paiement.dart';
import '../models/adherent.dart';
import '../config/app_colors.dart';
import '../widgets/searchable_adherent_dropdown.dart';
import '../widgets/searchable_year_dropdown.dart';

class ListePaiementsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ListePaiementsScreen> createState() => _ListePaiementsScreenState();
}

class _ListePaiementsScreenState extends ConsumerState<ListePaiementsScreen> {
  String _selectedFilter = 'Tous';
  int? _selectedAnnee;
  String? _selectedAdherentId;
  List<Adherent> _adherents = [];
  Set<String> _expandedCards = <String>{};

  @override
  void initState() {
    super.initState();
    // Retarder le chargement des données après la construction du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await ref.read(paiementProvider.notifier).loadPaiements();
    await ref.read(adherentProvider.notifier).loadAdherents();

    final adherentsAsync = ref.read(adherentProvider);
    final paiementsAsync = ref.read(paiementProvider);
    
    if (adherentsAsync.hasValue) {
      setState(() {
        _adherents = adherentsAsync.value!;
      });
    }
    
    // Debug: Afficher les IDs des paiements et adhérents pour diagnostic
    if (paiementsAsync.hasValue) {
      print('DEBUG: Liste des paiements:');
      for (var paiement in paiementsAsync.value!) {
        print('  - Paiement ID: ${paiement.id}, AdherentID: ${paiement.adherentId}, Montant: ${paiement.montantVerse}');
      }
    }
    
    if (adherentsAsync.hasValue) {
      print('DEBUG: Liste des adhérents:');
      for (var adherent in adherentsAsync.value!) {
        print('  - Adherent ID: ${adherent.id}, Nom: ${adherent.nomComplet}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paiementsAsync = ref.watch(paiementProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      
      body: Column(
        children: [
          _buildFilters(),
          _buildStatsHeader(),
          Expanded(
            child: paiementsAsync.when(
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
              data: (paiements) => _buildDataState(paiements),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.toSurface(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.filter_list,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Filtre principal
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtrer par:',
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _buildFilterChip('Tous', 'Tous'),
                SizedBox(width: 8),
                _buildFilterChip('Annee', 'Année'),
                SizedBox(width: 8),
                _buildFilterChip('Adherent', 'Adhérent'),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Contenu du filtre sélectionné
          if (_selectedFilter == 'Annee')
            _buildAnneeFilter(),
          if (_selectedFilter == 'Adherent')
            _buildAdherentFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
          _selectedAnnee = null;
          _selectedAdherentId = null;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getSurfaceColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.getBorderColor(isDark),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.getTextColor(isDark),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAnneeFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Text(
                'Année:',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SearchableYearDropdown(
            label: 'Rechercher une année',
            selectedYear: _selectedAnnee,
            years: _getAnnees(),
            onChanged: (int? value) {
              setState(() {
                _selectedAnnee = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdherentFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedAdherent = _selectedAdherentId != null 
        ? _adherents.firstWhere((a) => a.id == _selectedAdherentId, orElse: () => _adherents.first)
        : null;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Text(
                'Adhérent:',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SearchableAdherentDropdown(
            label: 'Rechercher un adhérent',
            selectedAdherent: selectedAdherent,
            adherents: _adherents,
            onChanged: (Adherent? value) {
              setState(() {
                _selectedAdherentId = value?.id;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final paiementsAsync = ref.read(paiementProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final paiements = paiementsAsync.maybeWhen(
      data: (paiements) => paiements,
      orElse: () => <Paiement>[],
    );
    
    final filteredPaiements = _filterPaiements(paiements);
    final totalAmount = filteredPaiements.fold<int>(0, (sum, p) => sum + p.montantVerse);
    
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total collecté',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$totalAmount FCFA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(height: 3),
                Text(
                  '${filteredPaiements.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'paiements',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeWidth: 3,
                ),
                SizedBox(height: 12),
                Text(
                  'Chargement des paiements...',
                  style: TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: Icon(Icons.refresh),
                label: Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataState(List<Paiement> paiements) {
    final filteredPaiements = _filterPaiements(paiements);
    
    if (filteredPaiements.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: filteredPaiements.length,
        itemBuilder: (context, index) {
          final paiement = filteredPaiements[index];
          final adherent = _adherents.firstWhere(
            (a) => a.id == paiement.adherentId,
            orElse: () => Adherent(
              nom: 'Adhérent', 
              prenom: 'inconnu (${paiement.adherentId})', 
              telephone: '', 
              montantAnnuelContribution: 0
            ),
          );
          return _buildPaiementCard(paiement, adherent);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(32),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.payment_outlined,
                  size: 64,
                  color: AppColors.grey500,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Aucun paiement trouvé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Effectuez des paiements pour voir l\'historique',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Paiement> _filterPaiements(List<Paiement> paiements) {
    switch (_selectedFilter) {
      case 'Annee':
        if (_selectedAnnee == null) return paiements;
        return paiements.where((p) => p.annee == _selectedAnnee).toList();
      case 'Adherent':
        if (_selectedAdherentId == null) return paiements;
        return paiements.where((p) => p.adherentId == _selectedAdherentId).toList();
      default:
        return paiements;
    }
  }

  Widget _buildPaiementCard(Paiement paiement, Adherent adherent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.getBorderColor(isDark),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleCardExpansion(paiement.id),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête compact avec infos essentielles
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getStatutColor(paiement.statut).toSurface(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatutIcon(paiement.statut),
                        color: _getStatutColor(paiement.statut),
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adherent.nomComplet.isNotEmpty ? adherent.nomComplet : 'Adhérent inconnu',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: AppColors.getTextColor(isDark),
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${paiement.annee}',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                DateFormat('dd MMM yyyy').format(paiement.datePaiement),
                                style: TextStyle(
                                  color: AppColors.getTextColor(isDark, type: TextType.secondary),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: AppColors.successGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            paiement.montantFormate,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Icon(
                          _expandedCards.contains(paiement.id) 
                              ? Icons.keyboard_arrow_up 
                              : Icons.keyboard_arrow_down,
                          color: AppColors.getTextColor(isDark, type: TextType.tertiary),
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Section expandable avec détails supplémentaires
                if (_expandedCards.contains(paiement.id)) ...[
                  SizedBox(height: 12),
                  Container(
                    height: 1,
                    color: AppColors.getBorderColor(isDark),
                  ),
                  SizedBox(height: 12),
                  _buildExpandedDetails(paiement, adherent, isDark),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCardExpansion(String paiementId) {
    setState(() {
      if (_expandedCards.contains(paiementId)) {
        _expandedCards.remove(paiementId);
      } else {
        _expandedCards.add(paiementId);
      }
    });
  }

  Widget _buildExpandedDetails(Paiement paiement, Adherent adherent, bool isDark) {
    return Column(
      children: [
        // Première ligne d'informations
        Row(
          children: [
            _buildDetailItem(
              Icons.payment,
              paiement.methodeFormate,
              'Méthode de paiement',
              isDark,
            ),
            SizedBox(width: 16),
            _buildDetailItem(
              Icons.info_outline,
              paiement.statutFormate,
              'Statut',
              isDark,
              color: _getStatutColor(paiement.statut),
            ),
          ],
        ),
        
        // Référence de transaction si disponible
        if (paiement.referenceTransaction != null && paiement.referenceTransaction!.isNotEmpty) ...[
          SizedBox(height: 12),
          _buildDetailItem(
            Icons.receipt_long,
            paiement.referenceTransaction!,
            'Référence de transaction',
            isDark,
          ),
        ],
        
        // Notes si disponibles
        if (paiement.notes != null && paiement.notes!.isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.grey300,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 16,
                      color: AppColors.grey600,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Notes',
                      style: TextStyle(
                        color: AppColors.getTextColor(isDark, type: TextType.secondary),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  paiement.notes!,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Actions supplémentaires
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.getBorderColor(isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String value, String label, bool isDark, {Color? color}) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).toSurface(),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color ?? AppColors.primary,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark, type: TextType.tertiary),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color ?? AppColors.getTextColor(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatutColor(StatutPaiement statut) {
    switch (statut) {
      case StatutPaiement.complete:
        return AppColors.success;
      case StatutPaiement.enAttente:
        return AppColors.warning;
      case StatutPaiement.partiel:
        return AppColors.warning;
      case StatutPaiement.retard:
        return AppColors.error;
    }
  }

  IconData _getStatutIcon(StatutPaiement statut) {
    switch (statut) {
      case StatutPaiement.complete:
        return Icons.check_circle;
      case StatutPaiement.enAttente:
        return Icons.pending;
      case StatutPaiement.partiel:
        return Icons.pie_chart;
      case StatutPaiement.retard:
        return Icons.warning;
    }
  }

  List<int> _getAnnees() {
    final paiementState = ref.read(paiementProvider);
    final paiements = paiementState.maybeWhen(
      data: (paiements) => paiements,
      orElse: () => <Paiement>[],
    );
    
    final annees = paiements.map((p) => p.annee).toSet().toList();
    annees.sort((a, b) => b.compareTo(a));
    return annees.isEmpty ? [DateTime.now().year] : annees;
  }
}
