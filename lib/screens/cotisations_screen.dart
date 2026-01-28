import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/cotisation_provider.dart';
import '../providers/adherent_provider.dart';
import '../models/cotisation.dart';
import '../models/adherent.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCotisationDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Année: $anneeSelectionnee',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => setState(() => anneeSelectionnee--),
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios),
                onPressed: () => setState(() => anneeSelectionnee++),
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
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCardHeader(cotisation, adherent, isExpanded),
                SizedBox(height: 12),
                _buildCardProgress(cotisation),
                if (isExpanded) ...[
                  SizedBox(height: 16),
                  _buildCardActions(cotisation, adherent),
                ] else ...[
                  SizedBox(height: 8),
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
    return Row(
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
              ),
              SizedBox(height: 4),
              Text(
                'Année ${cotisation.annee}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cotisation.estSoldee 
                ? Colors.green.withOpacity(0.1)
                : cotisation.montantPaye > 0 
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
          ),
          child: Text(
            cotisation.statut,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cotisation.estSoldee 
                  ? Colors.green.shade700
                  : cotisation.montantPaye > 0 
                      ? Colors.orange.shade700
                      : Colors.red.shade700,
            ),
          ),
        ),
        SizedBox(width: 8),
        AnimatedRotation(
          turns: isExpanded ? 0.5 : 0,
          duration: Duration(milliseconds: 300),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCardProgress(Cotisation cotisation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  cotisation.montantFormate,
                  style: TextStyle(
                    fontSize: 14,
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
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  cotisation.montantPayeFormate,
                  style: TextStyle(
                    fontSize: 14,
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
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  cotisation.resteFormate,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cotisation.resteAPayer > 0 ? Colors.red.shade600 : Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                backgroundColor: AppColors.primary,
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
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
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
              onPressed: _isLoading ? null : _saveCotisation,
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
                  : Text(
                      widget.cotisation == null ? 'Enregistrer' : 'Modifier',
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

      await Future.delayed(const Duration(milliseconds: 500));

      if (widget.cotisation == null) {
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
      setState(() => _isLoading = false);
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
}
