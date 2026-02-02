import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/adherent.dart';
import '../models/cotisation.dart';
import '../models/paiement.dart';
import '../models/benefice.dart';
import '../models/rapport.dart';
import '../providers/adherent_provider.dart';
import '../providers/cotisation_provider.dart';
import '../providers/paiement_provider.dart';
import '../providers/benefice_provider.dart';
import '../providers/rapport_provider.dart';
import '../services/calcul_service.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

class RapportsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends ConsumerState<RapportsScreen> {
  int anneeSelectionnee = DateTime.now().year;
  String _typeRapport = 'global';
  TypeRapport? _typeFiltre;
  String? _adherentFiltre;
  DateTime? _dateDebutFiltre;
  DateTime? _dateFinFiltre;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _useAdvancedMode = true;

  @override
  void initState() {
    super.initState();
    // Forcer le chargement des rapports au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rapportProvider.notifier).loadRapports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adherentsAsync = ref.watch(adherentProvider);
    final cotisationsAsync = ref.watch(cotisationProvider);
    final paiementsAsync = ref.watch(paiementProvider);
    final beneficesAsync = ref.watch(beneficeProvider);
    final rapportsAsync = ref.watch(rapportProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Rapports'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_useAdvancedMode ? Icons.view_list : Icons.dashboard),
            onPressed: () => setState(() => _useAdvancedMode = !_useAdvancedMode),
            tooltip: _useAdvancedMode ? 'Mode simple' : 'Mode avancé',
          ),
          if (_useAdvancedMode) ...[
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => ref.read(rapportProvider.notifier).loadRapports(),
            ),
          ],
        ],
      ),
      body: _useAdvancedMode ? _buildAdvancedMode(rapportsAsync, adherentsAsync) : _buildSimpleMode(adherentsAsync, cotisationsAsync, paiementsAsync, beneficesAsync),
      floatingActionButton: FloatingActionButton(
        onPressed: _useAdvancedMode ? () => _showGenerateRapportDialog() : () => _exporterRapport(context),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(_useAdvancedMode ? Icons.add_chart : Icons.download),
        tooltip: _useAdvancedMode ? 'Générer un rapport' : 'Exporter',
      ),
    );
  }

  Widget _buildAdvancedMode(AsyncValue<List<Rapport>> rapportsAsync, AsyncValue<List<Adherent>> adherentsAsync) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFiltersChips(),
        Expanded(
          child: rapportsAsync.when(
            loading: () => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des rapports...', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Erreur de chargement des rapports', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8),
                  Text('Détails: $error', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.read(rapportProvider.notifier).loadRapports(),
                    child: Text('Réessayer'),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _showGenerateRapportDialog,
                    child: Text('Générer un nouveau rapport'),
                  ),
                ],
              ),
            ),
            data: (rapports) => adherentsAsync.when(
              loading: () => LoadingWidget(),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
              data: (adherents) => _buildRapportsList(rapports, adherents),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleMode(AsyncValue<List<Adherent>> adherentsAsync, AsyncValue<List<Cotisation>> cotisationsAsync, AsyncValue<List<Paiement>> paiementsAsync, AsyncValue<List<Benefice>> beneficesAsync) {
    return Column(
      children: [
        _buildHeader(),
        _buildTypeSelector(),
        Expanded(
          child: adherentsAsync.when(
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
                    onPressed: () => _refreshData(),
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            ),
            data: (adherents) => cotisationsAsync.when(
              loading: () => LoadingWidget(),
              error: (error, stack) => Center(child: Text('Erreur: $error')),
              data: (cotisations) => paiementsAsync.when(
                loading: () => LoadingWidget(),
                error: (error, stack) => Center(child: Text('Erreur: $error')),
                data: (paiements) => beneficesAsync.when(
                  loading: () => LoadingWidget(),
                  error: (error, stack) => Center(child: Text('Erreur: $error')),
                  data: (benefices) => _buildRapportContent(adherents, cotisations, paiements, benefices),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un rapport...',
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

  Widget _buildFiltersChips() {
    if (_typeFiltre == null && _adherentFiltre == null && _dateDebutFiltre == null && _dateFinFiltre == null) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          if (_typeFiltre != null)
            Chip(
              label: Text('Type: ${_typeFiltre.toString().split('.').last}'),
              onDeleted: () => setState(() => _typeFiltre = null),
            ),
          if (_adherentFiltre != null)
            Chip(
              label: Text('Adhérent: $_adherentFiltre'),
              onDeleted: () => setState(() => _adherentFiltre = null),
            ),
          if (_dateDebutFiltre != null && _dateFinFiltre != null)
            Chip(
              label: Text('Période: ${DateFormat('dd/MM/yyyy').format(_dateDebutFiltre!)} - ${DateFormat('dd/MM/yyyy').format(_dateFinFiltre!)}'),
              onDeleted: () => setState(() {
                _dateDebutFiltre = null;
                _dateFinFiltre = null;
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildRapportsList(List<Rapport> rapports, List<Adherent> adherents) {
    // Filtrer les rapports
    List<Rapport> rapportsFiltres = rapports;

    if (_typeFiltre != null) {
      rapportsFiltres = rapportsFiltres.where((r) => r.type == _typeFiltre).toList();
    }

    if (_adherentFiltre != null) {
      rapportsFiltres = rapportsFiltres.where((r) => r.adherentId == _adherentFiltre).toList();
    }

    if (_dateDebutFiltre != null && _dateFinFiltre != null) {
      rapportsFiltres = rapportsFiltres.where((r) {
        return r.dateDebut.isAfter(_dateDebutFiltre!.subtract(Duration(days: 1))) && 
               r.dateFin.isBefore(_dateFinFiltre!.add(Duration(days: 1)));
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final lowerQuery = _searchQuery.toLowerCase();
      rapportsFiltres = rapportsFiltres.where((rapport) {
        return rapport.titre.toLowerCase().contains(lowerQuery) ||
            rapport.description.toLowerCase().contains(lowerQuery) ||
            rapport.typeFormate.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    if (rapportsFiltres.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.assessment,
        title: 'Aucun rapport trouvé',
        subtitle: _searchQuery.isNotEmpty || _typeFiltre != null || _adherentFiltre != null
            ? 'Aucun rapport ne correspond à vos critères de recherche'
            : 'Commencez par générer votre premier rapport',
        action: FloatingActionButton(
          onPressed: _showGenerateRapportDialog,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.add_chart),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(rapportProvider.notifier).loadRapports(),
      child: ListView.builder(
        itemCount: rapportsFiltres.length,
        itemBuilder: (context, index) {
          final rapport = rapportsFiltres[index];
          return _buildRapportCard(rapport, adherents);
        },
      ),
    );
  }

  Widget _buildRapportCard(Rapport rapport, List<Adherent> adherents) {
    final adherent = rapport.adherentId != null
        ? adherents.firstWhere(
              (a) => a.id == rapport.adherentId,
          orElse: () => Adherent(nom: 'Inconnu', prenom: '', telephone: ''),
        )
        : null;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(rapport.type).withOpacity(0.1),
          child: Icon(
            _getTypeIcon(rapport.type),
            color: _getTypeColor(rapport.type),
          ),
        ),
        title: Text(
          rapport.titre,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text('Type: ${rapport.typeFormate} • Période: ${rapport.periodeFormate}'),
            SizedBox(height: 4),
            Text('Période: ${rapport.periodeTexte}'),
            if (adherent != null) ...[
              SizedBox(height: 4),
              Text('Adhérent: ${adherent.nomComplet}'),
            ],
            SizedBox(height: 4),
            Text(
              'Généré le: ${DateFormat('dd MMM yyyy à HH:mm').format(rapport.dateGeneration)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _getResumeStatistiques(rapport),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, rapport),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text('Voir'),
                    ],
                  ),
                ),
                if (rapport.estModifiable) ...[
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 16),
                        SizedBox(width: 8),
                        Text('Dupliquer'),
                      ],
                    ),
                  ),
                ],
                PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 16),
                      SizedBox(width: 8),
                      Text('Exporter'),
                    ],
                  ),
                ),
                if (rapport.estModifiable)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () => _showRapportDetails(rapport, adherent),
      ),
    );
  }

  Color _getTypeColor(TypeRapport type) {
    switch (type) {
      case TypeRapport.cotisations:
        return Colors.blue;
      case TypeRapport.benefices:
        return Colors.green;
      case TypeRapport.global:
        return Colors.purple;
      case TypeRapport.adherent:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(TypeRapport type) {
    switch (type) {
      case TypeRapport.cotisations:
        return Icons.money;
      case TypeRapport.benefices:
        return Icons.trending_up;
      case TypeRapport.global:
        return Icons.assessment;
      case TypeRapport.adherent:
        return Icons.person;
    }
  }

  String _getResumeStatistiques(Rapport rapport) {
    switch (rapport.type) {
      case TypeRapport.cotisations:
        return '${rapport.totalCotisationsFormate}\n${rapport.nombreCotisations} cotisations';
      case TypeRapport.benefices:
        return '${rapport.totalBeneficesFormate}\n${rapport.donnees['nombreBenefices'] ?? 0} bénéfices';
      case TypeRapport.global:
        final solde = (rapport.donnees['solde'] ?? 0).toDouble();
        return '${solde.toInt()} FCFA\nSolde global';
      case TypeRapport.adherent:
        return '${rapport.totalCotisationsFormate}\n${rapport.nombreCotisations} cotisations';
    }
  }

  void _handleMenuAction(String action, Rapport rapport) {
    switch (action) {
      case 'view':
        _showRapportDetails(rapport, null);
        break;
      case 'edit':
        _showEditRapportDialog(rapport);
        break;
      case 'duplicate':
        _showDuplicateRapportDialog(rapport);
        break;
      case 'export':
        _showExportDialog(rapport);
        break;
      case 'delete':
        _showDeleteConfirmation(rapport);
        break;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        typeFiltre: _typeFiltre,
        adherentFiltre: _adherentFiltre,
        dateDebutFiltre: _dateDebutFiltre,
        dateFinFiltre: _dateFinFiltre,
        onApply: (type, adherent, dateDebut, dateFin) {
          setState(() {
            _typeFiltre = type;
            _adherentFiltre = adherent;
            _dateDebutFiltre = dateDebut;
            _dateFinFiltre = dateFin;
          });
        },
      ),
    );
  }

  void _showGenerateRapportDialog() {
    showDialog(
      context: context,
      builder: (context) => GenerateRapportDialog(),
    );
  }

  void _showRapportDetails(Rapport rapport, Adherent? adherent) {
    showDialog(
      context: context,
      builder: (context) => RapportDetailsDialog(rapport: rapport, adherent: adherent),
    );
  }

  void _showEditRapportDialog(Rapport rapport) {
    showDialog(
      context: context,
      builder: (context) => EditRapportDialog(rapport: rapport),
    ).then((_) {
      ref.read(rapportProvider.notifier).loadRapports();
    });
  }

  void _showDuplicateRapportDialog(Rapport rapport) {
    showDialog(
      context: context,
      builder: (context) => DuplicateRapportDialog(rapportOriginal: rapport),
    ).then((_) {
      ref.read(rapportProvider.notifier).loadRapports();
    });
  }

  void _showExportDialog(Rapport rapport) {
    showDialog(
      context: context,
      builder: (context) => ExportRapportDialog(rapport: rapport),
    );
  }

  void _showDeleteConfirmation(Rapport rapport) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le rapport'),
        content: Text('Êtes-vous sûr de vouloir supprimer le rapport "${rapport.titre}" ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(rapportProvider.notifier).deleteRapport(rapport.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rapport supprimé avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer'),
          ),
        ],
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

  Widget _buildTypeSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: Text('Global'),
              selected: _typeRapport == 'global',
              onSelected: (selected) => setState(() => _typeRapport = 'global'),
            ),
            SizedBox(width: 8),
            FilterChip(
              label: Text('Cotisations'),
              selected: _typeRapport == 'cotisations',
              onSelected: (selected) => setState(() => _typeRapport = 'cotisations'),
            ),
            SizedBox(width: 8),
            FilterChip(
              label: Text('Paiements'),
              selected: _typeRapport == 'paiements',
              onSelected: (selected) => setState(() => _typeRapport = 'paiements'),
            ),
            SizedBox(width: 8),
            FilterChip(
              label: Text('Bénéfices'),
              selected: _typeRapport == 'benefices',
              onSelected: (selected) => setState(() => _typeRapport = 'benefices'),
            ),
            SizedBox(width: 8),
            FilterChip(
              label: Text('Adhérents'),
              selected: _typeRapport == 'adherents',
              onSelected: (selected) => setState(() => _typeRapport = 'adherents'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRapportContent(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements, List<Benefice> benefices) {
    switch (_typeRapport) {
      case 'global':
        return _buildGlobalRapport(adherents, cotisations, paiements, benefices);
      case 'cotisations':
        return _buildCotisationsRapport(cotisations, adherents);
      case 'paiements':
        return _buildPaiementsRapport(paiements, adherents);
      case 'benefices':
        return _buildBeneficesRapport(benefices, adherents);
      case 'adherents':
        return _buildAdherentsRapport(adherents);
      default:
        return Center(child: Text('Type de rapport non implémenté'));
    }
  }

  Widget _buildGlobalRapport(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements, List<Benefice> benefices) {
    final statistiques = CalculService.genererStatistiques(
      adherents,
      cotisations,
      paiements,
      anneeSelectionnee,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24),
          _buildStatistiquesCards(statistiques),
          SizedBox(height: 24),
          _buildResumeSection(statistiques),
        ],
      ),
    );
  }

  Widget _buildStatistiquesCards(Map<String, dynamic> statistiques) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 32, color: Colors.blue),
                SizedBox(height: 8),
                Text('${statistiques['nombreAdherents']}'),
                Text('Adhérents Actifs', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance, size: 32, color: Colors.green),
                SizedBox(height: 8),
                Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(statistiques['totalCotisationsAnnee'])}'),
                Text('Cotisations Annuelles', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payments, size: 32, color: Colors.orange),
                SizedBox(height: 8),
                Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(statistiques['totalPayementsAnnee'])}'),
                Text('Montant Collecté', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 32, color: Colors.purple),
                SizedBox(height: 8),
                Text('${statistiques['tauxRecouvrement'].toStringAsFixed(1)}%'),
                Text('Taux Recouvrement', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeSection(Map<String, dynamic> statistiques) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildResumeRow('Adhérents à jour', '${statistiques['adherentsAJour']}'),
            _buildResumeRow('Adhérents en retard', '${statistiques['adherentsRetard']}'),
            _buildResumeRow('Montant restant', '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(statistiques['montantRestant'])}'),
            _buildResumeRow('Performance globale', '${statistiques['tauxRecouvrement'].toStringAsFixed(1)}%', isHighlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCotisationsRapport(List<Cotisation> cotisations, List<Adherent> adherents) {
    // Filtrer les cotisations pour l'année sélectionnée
    final cotisationsAnnee = cotisations.where((c) => c.annee == anneeSelectionnee).toList();
    
    // Calculer les statistiques
    final totalCotisations = cotisationsAnnee.fold<double>(0, (sum, c) => sum + c.montantPaye);
    final totalAttendu = cotisationsAnnee.fold<double>(0, (sum, c) => sum + c.montantAnnuel);
    final totalRestant = cotisationsAnnee.fold<double>(0, (sum, c) => sum + c.resteAPayer);
    final cotisationsSoldees = cotisationsAnnee.where((c) => c.estSoldee).length;
    final tauxRecouvrement = totalAttendu > 0 ? (totalCotisations / totalAttendu * 100) : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartes de statistiques
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 32, color: Colors.blue),
                      SizedBox(height: 8),
                      Text('${cotisationsAnnee.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Cotisations $anneeSelectionnee', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 32, color: Colors.green),
                      SizedBox(height: 8),
                      Text('$cotisationsSoldees', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Cotisations soldées', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money, size: 32, color: Colors.orange),
                      SizedBox(height: 8),
                      Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalCotisations)}', 
                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Montant collecté', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up, size: 32, color: Colors.purple),
                      SizedBox(height: 8),
                      Text('${tauxRecouvrement.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Taux recouvrement', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Résumé détaillé
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résumé financier $anneeSelectionnee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  _buildResumeRow('Total attendu', NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalAttendu)),
                  _buildResumeRow('Montant collecté', NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalCotisations), isHighlight: true),
                  _buildResumeRow('Reste à collecter', NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalRestant)),
                  _buildResumeRow('Taux de recouvrement', '${tauxRecouvrement.toStringAsFixed(1)}%', isHighlight: true),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Liste des cotisations détaillées
          Text('Détail des cotisations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: cotisationsAnnee.length,
            itemBuilder: (context, index) {
              final cotisation = cotisationsAnnee[index];
              final adherent = adherents.firstWhere(
                (a) => a.id == cotisation.adherentId,
                orElse: () => Adherent(nom: 'Inconnu', prenom: '', telephone: ''),
              );
              
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                    backgroundColor: cotisation.estSoldee ? Colors.green : Colors.orange,
                  ),
                  title: Text(adherent.nomComplet),
                  subtitle: Text('Année ${cotisation.annee}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(cotisation.montantPaye)}', 
                           style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${cotisation.pourcentagePaye.toStringAsFixed(1)}%', 
                           style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaiementsRapport(List<Paiement> paiements, List<Adherent> adherents) {
    // Filtrer les paiements pour l'année sélectionnée
    final paiementsAnnee = paiements.where((p) => p.datePaiement.year == anneeSelectionnee).toList();
    
    // Calculer les statistiques
    final totalPaiements = paiementsAnnee.fold<double>(0, (sum, p) => sum + p.montantVerse);
    final nombrePaiements = paiementsAnnee.length;
    final montantMoyen = nombrePaiements > 0 ? totalPaiements / nombrePaiements : 0.0;
    
    // Grouper par mois
    final Map<int, double> paiementsParMois = {};
    for (var paiement in paiementsAnnee) {
      final mois = paiement.datePaiement.month;
      paiementsParMois[mois] = (paiementsParMois[mois] ?? 0) + paiement.montantVerse;
    }
    
    // Grouper par adhérent
    final Map<String, double> paiementsParAdherent = {};
    for (var paiement in paiementsAnnee) {
      paiementsParAdherent[paiement.adherentId] = (paiementsParAdherent[paiement.adherentId] ?? 0) + paiement.montantVerse;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartes de statistiques
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 32, color: Colors.green),
                      SizedBox(height: 8),
                      Text('$nombrePaiements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Paiements $anneeSelectionnee', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 32, color: Colors.blue),
                      SizedBox(height: 8),
                      Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalPaiements)}', 
                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Total collecté', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate, size: 32, color: Colors.orange),
                      SizedBox(height: 8),
                      Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(montantMoyen)}', 
                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Moyenne/paiement', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 32, color: Colors.purple),
                      SizedBox(height: 8),
                      Text('${paiementsParAdherent.keys.length}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Adhérents actifs', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Paiements par mois
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paiements par mois', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  ...List.generate(12, (index) {
                    final mois = index + 1;
                    final montant = paiementsParMois[mois] ?? 0.0;
                    final nomsMois = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
                    
                    return _buildResumeRow(
                      nomsMois[index],
                      NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(montant),
                      isHighlight: montant > 0,
                    );
                  }),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Top adhérents
          Text('Top adhérents par montant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ...(() {
            final sortedEntries = paiementsParAdherent.entries.toList();
            sortedEntries.sort((a, b) => b.value.compareTo(a.value));
            
            return sortedEntries.take(10).map((entry) {
              final adherent = adherents.firstWhere(
                (a) => a.id == entry.key,
                orElse: () => Adherent(nom: 'Inconnu', prenom: '', telephone: ''),
              );
              
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                    backgroundColor: Colors.blue,
                  ),
                  title: Text(adherent.nomComplet),
                  trailing: Text(
                    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(entry.value),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList();
          })(),
        ],
      ),
    );
  }

  Widget _buildBeneficesRapport(List<Benefice> benefices, List<Adherent> adherents) {
    // Filtrer les bénéfices pour l'année sélectionnée
    final beneficesAnnee = benefices.where((b) => b.annee == anneeSelectionnee).toList();
    
    // Calculer les statistiques
    final totalBenefices = beneficesAnnee.fold<double>(0, (sum, b) => sum + b.montantTotal);
    final nombreBenefices = beneficesAnnee.length;
    final beneficesDistribues = beneficesAnnee.where((b) => b.estDistribue).length;
    final beneficesNonDistribues = nombreBenefices - beneficesDistribues;
    final montantMoyen = nombreBenefices > 0 ? totalBenefices / nombreBenefices : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartes de statistiques
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard, size: 32, color: Colors.green),
                      SizedBox(height: 8),
                      Text('$nombreBenefices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Bénéfices $anneeSelectionnee', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.attach_money, size: 32, color: Colors.blue),
                      SizedBox(height: 8),
                      Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalBenefices)}', 
                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Total bénéfices', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 32, color: Colors.orange),
                      SizedBox(height: 8),
                      Text('$beneficesDistribues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Bénéfices distribués', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pending, size: 32, color: Colors.red),
                      SizedBox(height: 8),
                      Text('$beneficesNonDistribues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('En attente', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Résumé détaillé
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résumé des bénéfices $anneeSelectionnee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  _buildResumeRow('Nombre total de bénéfices', '$nombreBenefices'),
                  _buildResumeRow('Montant total', NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalBenefices), isHighlight: true),
                  _buildResumeRow('Moyenne par bénéfice', NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(montantMoyen)),
                  _buildResumeRow('Bénéfices distribués', '$beneficesDistribues / $nombreBenefices'),
                  _buildResumeRow('Taux de distribution', nombreBenefices > 0 ? '${(beneficesDistribues / nombreBenefices * 100).toStringAsFixed(1)}%' : '0%'),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Liste des bénéfices détaillés
          Text('Détail des bénéfices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: beneficesAnnee.length,
            itemBuilder: (context, index) {
              final benefice = beneficesAnnee[index];
              
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.card_giftcard, color: Colors.white),
                    backgroundColor: benefice.estDistribue ? Colors.green : Colors.orange,
                  ),
                  title: Text('Bénéfice ${benefice.annee}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (benefice.description.isNotEmpty) Text(benefice.description),
                      Text('Distribution: ${DateFormat('dd MMM yyyy').format(benefice.dateDistribution)}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(benefice.montantTotal)}', 
                           style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        benefice.estDistribue ? 'Distribué' : 'En attente',
                        style: TextStyle(
                          fontSize: 12,
                          color: benefice.estDistribue ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdherentsRapport(List<Adherent> adherents) {
    // Calculer les statistiques
    final totalAdherents = adherents.length;
    final adherentsActifs = adherents.where((a) => a.estActif).length;
    final adherentsInactifs = totalAdherents - adherentsActifs;
    
    // Calculer les statistiques par année d'adhésion
    final Map<int, int> adherentsParAnnee = {};
    for (var adherent in adherents) {
      final annee = adherent.dateAdhesion.year;
      adherentsParAnnee[annee] = (adherentsParAnnee[annee] ?? 0) + 1;
    }
    
    // Calculer la contribution totale attendue
    final contributionTotale = adherents.fold<double>(0, (sum, a) => sum + a.montantAnnuelContribution);
    final contributionMoyenne = totalAdherents > 0 ? contributionTotale / totalAdherents : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cartes de statistiques
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 32, color: Colors.blue),
                      SizedBox(height: 8),
                      Text('$totalAdherents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Total adhérents', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 32, color: Colors.green),
                      SizedBox(height: 8),
                      Text('$adherentsActifs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Adhérents actifs', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.money, size: 32, color: Colors.orange),
                      SizedBox(height: 8),
                      Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(contributionTotale)}', 
                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Contributions annuelles', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate, size: 32, color: Colors.purple),
                      SizedBox(height: 8),
                      Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(contributionMoyenne)}', 
                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Contribution moyenne', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24),
          
          // Résumé détaillé
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Résumé des adhérents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  _buildResumeRow('Total adhérents', '$totalAdherents'),
                  _buildResumeRow('Adhérents actifs', '$adherentsActifs', isHighlight: true),
                  _buildResumeRow('Adhérents inactifs', '$adherentsInactifs'),
                  _buildResumeRow('Taux d\'activité', totalAdherents > 0 ? '${(adherentsActifs / totalAdherents * 100).toStringAsFixed(1)}%' : '0%'),
                  _buildResumeRow('Contribution totale', NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(contributionTotale)),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Adhérents par année d'adhésion
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adhérents par année d\'adhésion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  ...(() {
                    final entries = adherentsParAnnee.entries.toList();
                    entries.sort((a, b) => b.key.compareTo(a.key));
                    return entries.map((entry) => _buildResumeRow(
                      'Année ${entry.key}',
                      '${entry.value} adhérent${entry.value > 1 ? 's' : ''}',
                      isHighlight: entry.key == DateTime.now().year,
                    )).toList();
                  })(),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Liste des adhérents détaillée
          Text('Liste des adhérents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: adherents.length,
            itemBuilder: (context, index) {
              final adherent = adherents[index];
              
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                    backgroundColor: adherent.estActif ? Colors.green : Colors.grey,
                  ),
                  title: Text(adherent.nomComplet),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Téléphone: ${adherent.telephone}'),
                      Text('Adhésion: ${DateFormat('dd MMM yyyy').format(adherent.dateAdhesion)}'),
                      if (adherent.email.isNotEmpty) Text('Email: ${adherent.email}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(adherent.montantAnnuelContribution)}', 
                           style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        adherent.estActif ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          fontSize: 12,
                          color: adherent.estActif ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    // Implémenter le rafraîchissement des données
  }

  Future<void> _exporterRapport(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportation du rapport - Fonctionnalité à implémenter')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'export: $e')),
      );
    }
  }
}

class FilterDialog extends StatefulWidget {
  final TypeRapport? typeFiltre;
  final String? adherentFiltre;
  final DateTime? dateDebutFiltre;
  final DateTime? dateFinFiltre;
  final Function(TypeRapport?, String?, DateTime?, DateTime?) onApply;

  const FilterDialog({
    Key? key,
    this.typeFiltre,
    this.adherentFiltre,
    this.dateDebutFiltre,
    this.dateFinFiltre,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  TypeRapport? _selectedType;
  String? _selectedAdherent;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.typeFiltre;
    _selectedAdherent = widget.adherentFiltre;
    _dateDebut = widget.dateDebutFiltre;
    _dateFin = widget.dateFinFiltre;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filtrer les rapports'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TypeRapport>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type de rapport',
                prefixIcon: Icon(Icons.category),
              ),
              items: TypeRapport.values.map((type) {
                return DropdownMenuItem<TypeRapport>(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Période'),
              subtitle: Text(_dateDebut != null && _dateFin != null
                  ? '${DateFormat('dd/MM/yyyy').format(_dateDebut!)} - ${DateFormat('dd/MM/yyyy').format(_dateFin!)}'
                  : 'Sélectionner une période'),
              trailing: Icon(Icons.calendar_today),
              onTap: _selectDateRange,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _selectedType = null;
              _selectedAdherent = null;
              _dateDebut = null;
              _dateFin = null;
            });
          },
          child: Text('Effacer'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_selectedType, _selectedAdherent, _dateDebut, _dateFin);
            Navigator.pop(context);
          },
          child: Text('Appliquer'),
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dateDebut = picked.start;
        _dateFin = picked.end;
      });
    }
  }
}

class GenerateRapportDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<GenerateRapportDialog> createState() => _GenerateRapportDialogState();
}

class _GenerateRapportDialogState extends ConsumerState<GenerateRapportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();
  
  TypeRapport _selectedType = TypeRapport.global;
  String? _selectedAdherentId;
  List<Adherent> _adherents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAdherents();
    _dateDebutController.text = DateFormat('dd/MM/yyyy').format(DateTime(DateTime.now().year, 1, 1));
    _dateFinController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _loadAdherents() async {
    final adherentsAsync = ref.read(adherentProvider);
    if (adherentsAsync.hasValue) {
      setState(() {
        _adherents = adherentsAsync.value!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Générer un rapport'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TypeRapport>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type de rapport *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: TypeRapport.values.map((type) {
                    return DropdownMenuItem<TypeRapport>(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                SizedBox(height: 16),
                
                if (_selectedType == TypeRapport.adherent) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedAdherentId,
                    decoration: InputDecoration(
                      labelText: 'Adhérent *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _adherents.map((adherent) {
                      return DropdownMenuItem<String>(
                        value: adherent.id,
                        child: Text(adherent.nomComplet),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedAdherentId = value),
                    validator: (value) => value == null ? 'Veuillez sélectionner un adhérent' : null,
                  ),
                  SizedBox(height: 16),
                ],
                
                TextFormField(
                  controller: _titreController,
                  decoration: InputDecoration(
                    labelText: 'Titre du rapport',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
                ),
                SizedBox(height: 16),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateDebutController,
                        decoration: InputDecoration(
                          labelText: 'Date de début *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: _selectDateDebut,
                        validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _dateFinController,
                        decoration: InputDecoration(
                          labelText: 'Date de fin *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: _selectDateFin,
                        validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _generateRapport,
          child: _isLoading 
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Générer'),
        ),
      ],
    );
  }

  Future<void> _selectDateDebut() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateDebutController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      _dateDebutController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _selectDateFin() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateFinController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      _dateFinController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _generateRapport() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);

    try {
      final dateDebut = DateFormat('dd/MM/yyyy').parse(_dateDebutController.text);
      final dateFin = DateFormat('dd/MM/yyyy').parse(_dateFinController.text);
      final titre = _titreController.text.trim();
      final description = _descriptionController.text.trim();

      Rapport rapport;

      switch (_selectedType) {
        case TypeRapport.cotisations:
          rapport = await ref.read(rapportProvider.notifier).genererRapportCotisations(
            dateDebut: dateDebut,
            dateFin: dateFin,
            adherentId: _selectedAdherentId,
            titre: titre.isNotEmpty ? titre : 'Rapport des cotisations',
            description: description,
          );
          break;
        case TypeRapport.benefices:
          rapport = await ref.read(rapportProvider.notifier).genererRapportBenefices(
            dateDebut: dateDebut,
            dateFin: dateFin,
            titre: titre.isNotEmpty ? titre : 'Rapport des bénéfices',
            description: description,
          );
          break;
        case TypeRapport.global:
          rapport = await ref.read(rapportProvider.notifier).genererRapportGlobal(
            dateDebut: dateDebut,
            dateFin: dateFin,
            adherentId: _selectedAdherentId,
            titre: titre.isNotEmpty ? titre : 'Rapport global',
            description: description,
          );
          break;
        case TypeRapport.adherent:
          if (_selectedAdherentId == null) {
            throw Exception('Veuillez sélectionner un adhérent');
          }
          rapport = await ref.read(rapportProvider.notifier).genererRapportAdherent(
            adherentId: _selectedAdherentId!,
            dateDebut: dateDebut,
            dateFin: dateFin,
            titre: titre.isNotEmpty ? titre : 'Rapport adhérent',
            description: description,
          );
          break;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapport généré avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la génération: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class RapportDetailsDialog extends StatelessWidget {
  final Rapport rapport;
  final Adherent? adherent;

  const RapportDetailsDialog({Key? key, required this.rapport, this.adherent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(rapport.titre),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', rapport.typeFormate),
              _buildDetailRow('Période', rapport.periodeFormate),
              _buildDetailRow('Date de début', DateFormat('dd/MM/yyyy').format(rapport.dateDebut)),
              _buildDetailRow('Date de fin', DateFormat('dd/MM/yyyy').format(rapport.dateFin)),
              if (adherent != null) ...[
                _buildDetailRow('Adhérent', adherent!.nomComplet),
                _buildDetailRow('Téléphone', adherent!.telephone),
              ],
              _buildDetailRow('Date de génération', DateFormat('dd MMM yyyy à HH:mm').format(rapport.dateGeneration)),
              if (rapport.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(rapport.description),
              ],
              SizedBox(height: 16),
              _buildStatistiquesSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatistiquesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            
            if (rapport.type == TypeRapport.cotisations || rapport.type == TypeRapport.adherent) ...[
              _buildStatRow('Total cotisations', rapport.totalCotisationsFormate),
              _buildStatRow('Nombre de cotisations', '${rapport.nombreCotisations}'),
              if (rapport.type == TypeRapport.adherent && rapport.donnees.containsKey('adherentNom'))
                _buildStatRow('Adhérent', rapport.donnees['adherentNom']),
            ],
            
            if (rapport.type == TypeRapport.benefices) ...[
              _buildStatRow('Total bénéfices', rapport.totalBeneficesFormate),
              _buildStatRow('Nombre de bénéfices', '${rapport.donnees['nombreBenefices'] ?? 0}'),
            ],
            
            if (rapport.type == TypeRapport.global) ...[
              _buildStatRow('Total cotisations', rapport.totalCotisationsFormate),
              _buildStatRow('Total bénéfices', rapport.totalBeneficesFormate),
              _buildStatRow('Solde global', '${(rapport.donnees['solde'] ?? 0).toInt()} FCFA'),
              _buildStatRow('Nombre d\'adhérents', '${rapport.nombreAdherents}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class EditRapportDialog extends StatefulWidget {
  final Rapport rapport;

  const EditRapportDialog({Key? key, required this.rapport}) : super(key: key);

  @override
  State<EditRapportDialog> createState() => _EditRapportDialogState();
}

class _EditRapportDialogState extends State<EditRapportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titreController.text = widget.rapport.titre;
    _descriptionController.text = widget.rapport.description;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modifier le rapport'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titreController,
              decoration: InputDecoration(
                labelText: 'Titre *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveRapport,
          child: Text('Enregistrer'),
        ),
      ],
    );
  }

  void _saveRapport() {
    if (_formKey.currentState?.validate() != true) return;

    final updatedRapport = widget.rapport.copyWith(
      titre: _titreController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    // Ici vous devrez appeler le provider pour mettre à jour le rapport
    Navigator.pop(context);
  }
}

class DuplicateRapportDialog extends ConsumerStatefulWidget {
  final Rapport rapportOriginal;

  const DuplicateRapportDialog({Key? key, required this.rapportOriginal}) : super(key: key);

  @override
  ConsumerState<DuplicateRapportDialog> createState() => _DuplicateRapportDialogState();
}

class _DuplicateRapportDialogState extends ConsumerState<DuplicateRapportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titreController.text = '${widget.rapportOriginal.titre} (copie)';
  }

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Dupliquer le rapport'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ce rapport sera dupliqué avec les mêmes données mais un nouveau titre.'),
            SizedBox(height: 16),
            TextFormField(
              controller: _titreController,
              decoration: InputDecoration(
                labelText: 'Titre du nouveau rapport *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _duplicateRapport,
          child: Text('Dupliquer'),
        ),
      ],
    );
  }

  void _duplicateRapport() {
    if (_formKey.currentState?.validate() != true) return;

    final duplicatedRapport = widget.rapportOriginal.copyWith(
      titre: _titreController.text.trim(),
      dateGeneration: DateTime.now(),
    );

    // Ici vous devrez appeler le provider pour ajouter le rapport dupliqué
    Navigator.pop(context);
  }
}

class ExportRapportDialog extends ConsumerWidget {
  final Rapport rapport;

  const ExportRapportDialog({Key? key, required this.rapport}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adherentsAsync = ref.watch(adherentProvider);

    return AlertDialog(
      title: Text('Exporter le rapport'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Choisissez le format d\'exportation:'),
          SizedBox(height: 16),
          ListTile(
            title: Text('PDF'),
            subtitle: Text('Format document portable avec mise en forme'),
            leading: Icon(Icons.picture_as_pdf, color: Colors.red),
            onTap: () => _export('pdf', context, ref, adherentsAsync),
          ),
          ListTile(
            title: Text('Excel (CSV)'),
            subtitle: Text('Format tableur pour Microsoft Excel'),
            leading: Icon(Icons.table_chart, color: Colors.green),
            onTap: () => _export('csv', context, ref, adherentsAsync),
          ),
          ListTile(
            title: Text('JSON'),
            subtitle: Text('Format de données structuré pour développeurs'),
            leading: Icon(Icons.code, color: Colors.blue),
            onTap: () => _export('json', context, ref, adherentsAsync),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
      ],
    );
  }

  void _export(String format, BuildContext context, WidgetRef ref, AsyncValue<List<Adherent>> adherentsAsync) async {
    Navigator.pop(context);

    if (!adherentsAsync.hasValue) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: données des adhérents non disponibles'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Afficher un indicateur de chargement
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 16),
              Text('Exportation en cours...'),
            ],
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ),
      );
    }

    try {
      await ref.read(rapportProvider.notifier).exporterRapport(
        rapport, 
        adherentsAsync.value!, 
        format: format,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport exporté avec succès en $format.toUpperCase()!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'exportation: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
