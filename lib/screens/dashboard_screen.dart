import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/adherent.dart';
import '../models/cotisation.dart';
import '../models/paiement.dart';
import '../models/benefice.dart';
import '../providers/adherent_provider.dart';
import '../providers/cotisation_provider.dart';
import '../providers/paiement_provider.dart';
import '../providers/benefice_provider.dart';
import '../services/theme_service.dart';
import '../config/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/custom_tab_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  int anneeSelectionnee = DateTime.now().year;
  late TabController _tabController;
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adherentsAsync = ref.watch(adherentProvider);
    final cotisationsAsync = ref.watch(cotisationProvider);
    final paiementsAsync = ref.watch(paiementProvider);
    final beneficesAsync = ref.watch(beneficeProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _rafraichirDonnees,
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
                  onPressed: _rafraichirDonnees,
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
                data: (benefices) => _buildBody(adherents, cotisations, paiements, benefices),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildWhatsAppFAB(adherentsAsync.value ?? [], cotisationsAsync.value ?? [], paiementsAsync.value ?? []),
    );
  }

  Widget _buildBody(
      List<Adherent> adherents,
      List<Cotisation> cotisations,
      List<Paiement> paiements,
      List<Benefice> benefices,
      ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur d'année
          _buildAnneeSelector(),
          SizedBox(height: 12),

          // Cartes de statistiques
          _buildStatistiquesGrid(adherents.cast<Adherent>(), cotisations.cast<Cotisation>(), paiements.cast<Paiement>()),
          // Menu tab scrollable pour les activités et adhérents en retard
          _buildTabSection(adherents.cast<Adherent>(), cotisations.cast<Cotisation>(), paiements.cast<Paiement>()),
        ],
      ),
    );
  }

  Widget _buildTabSection(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements) {
    return Column(
      children: [
        // TabBar personnalisé unifié - hauteur réduite
        CustomTabBar(
          height: 32, // Réduit de 40 à 32
          controller: _tabController,
          tabs: [
            TabItem(
              title: 'Activités',
              icon: Icons.history_outlined,
            ),
            TabItem(
              title: 'Retards',
              icon: Icons.warning_amber_outlined,
            ),
          ],
        ),
        SizedBox(height: 8), // Réduit de 16 à 8
        
        // TabBarView avec le contenu - hauteur réduite
        Container(
          height: 320, // Réduit de 400 à 320
          child: TabBarView(
            controller: _tabController,
            children: [
              // Onglet 1: Activités récentes
              _buildActivitiesTab(adherents, cotisations, paiements),
              // Onglet 2: Adhérents en retard
              _buildRetardTab(adherents, cotisations, paiements),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesTab(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements) {
    final isDarkMode = _themeService.isDarkMode;
    final activities = <Map<String, dynamic>>[];

    // Ajouter les paiements récents
    for (var paiement in paiements.take(10)) {
      activities.add({
        'type': 'paiement',
        'title': 'Paiement reçu',
        'description': NumberFormat.currency(locale: 'fr_FR', symbol: '').format(paiement.montantVerse),
        'date': paiement.datePaiement,
        'icon': Icons.payment,
        'color': AppColors.success,
      });
    }

    // Ajouter les nouvelles cotisations
    for (var cotisation in cotisations.take(5)) {
      activities.add({
        'type': 'cotisation',
        'title': 'Nouvelle cotisation',
        'description': NumberFormat.currency(locale: 'fr_FR', symbol: '').format(cotisation.montantAnnuel),
        'date': cotisation.dateModification,
        'icon': Icons.account_balance,
        'color': AppColors.primary,
      });
    }

    // Trier par date
    activities.sort((a, b) => b['date'].compareTo(a['date']));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.getSurfaceColor(isDarkMode),
      ),
      child: activities.isEmpty
          ? EmptyStateWidget(
              icon: Icons.history,
              title: 'Aucune activité',
              subtitle: 'Aucune activité récente à afficher',
            )
          : ListView.separated(
              padding: EdgeInsets.all(8),
              itemCount: activities.length,
              separatorBuilder: (context, index) => SizedBox(height: 6),
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(isDarkMode),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.getBorderColor(isDarkMode),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode 
                            ? Colors.black.withOpacity(0.1)
                            : Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: activity['color'].withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            activity['icon'], 
                            color: activity['color'], 
                            size: 16
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity['title'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.getTextColor(isDarkMode),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2),
                              Text(
                                activity['description'],
                                style: TextStyle(
                                  color: AppColors.getTextColor(isDarkMode, type: TextType.secondary),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('dd MMM', 'fr').format(activity['date']),
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                color: AppColors.getTextColor(isDarkMode),
                              ),
                            ),
                            SizedBox(height: 1),
                            Text(
                              DateFormat('HH:mm', 'fr').format(activity['date']),
                              style: TextStyle(
                                color: AppColors.getTextColor(isDarkMode, type: TextType.tertiary),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRetardTab(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements) {
    final isDarkMode = _themeService.isDarkMode;
    final adherentsRetard = <Map<String, dynamic>>[];
    String? _expandedCardKey;

    for (var adherent in adherents.where((a) => a.estActif == true)) {
      final cotisationsAnnee = cotisations.where(
            (c) => c.adherentId == adherent.id && c.annee == anneeSelectionnee,
      ).toList();

      if (cotisationsAnnee.isNotEmpty) {
        final cotisationAnnee = cotisationsAnnee.first;
        final paiementAnnee = paiements.where(
              (p) => p.adherentId == adherent.id && p.annee == anneeSelectionnee,
        ).toList();

        final totalPaye = paiementAnnee.fold<int>(0, (sum, p) => sum + p.montantVerse);
        final montantDu = cotisationAnnee.montantAnnuel;

        if (totalPaye < montantDu) {
          adherentsRetard.add({
            'adherent': adherent,
            'montantDu': montantDu - totalPaye,
            'totalPaye': totalPaye,
            'montantTotal': montantDu,
          });
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.getSurfaceColor(isDarkMode),
      ),
      child: adherentsRetard.isEmpty
          ? EmptyStateWidget(
              icon: Icons.check_circle_outline,
              title: 'Aucun retard',
              subtitle: 'Tous les adhérents sont à jour',
            )
          : StatefulBuilder(
              builder: (context, setState) {
                return ListView.separated(
                  padding: EdgeInsets.all(8),
                  itemCount: adherentsRetard.length,
                  separatorBuilder: (context, index) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = adherentsRetard[index];
                    final adherent = item['adherent'];
                    final pourcentagePaye = (item['totalPaye'] / item['montantTotal'] * 100);
                    final cardKey = adherent.id;
                    final isExpanded = _expandedCardKey == cardKey;
                    
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.errorSurface,
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(isExpanded ? 0.15 : 0.1),
                            blurRadius: isExpanded ? 12 : 6,
                            offset: Offset(0, isExpanded ? 6 : 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            setState(() {
                              if (_expandedCardKey == cardKey) {
                                _expandedCardKey = null;
                              } else {
                                _expandedCardKey = cardKey;
                              }
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.all(isExpanded ? 16 : 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAdherentHeader(adherent, pourcentagePaye, isExpanded),
                                SizedBox(height: isExpanded ? 12 : 8),
                                _buildPaymentProgress(item, pourcentagePaye, isExpanded),
                                if (isExpanded) ...[
                                  SizedBox(height: 12),
                                  _buildDetailedInfo(item, pourcentagePaye),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildAdherentHeader(Adherent adherent, double pourcentagePaye, bool isExpanded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.error.withOpacity(0.15),
                    AppColors.error.withOpacity(0.05),
                  ],
                ),
              ),
              child: Icon(
                Icons.person_outline,
                color: AppColors.error,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${adherent.nom} ${adherent.prenom}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(_themeService.isDarkMode),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.error.withOpacity(0.06),
                        ),
                        child: Text(
                          'En retard',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        '• $anneeSelectionnee',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (isExpanded && pourcentagePaye > 0) ...[
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: pourcentagePaye >= 50 
                                ? AppColors.success.withOpacity(0.1)
                                : pourcentagePaye >= 25 
                                    ? AppColors.warning.withOpacity(0.1)
                                    : AppColors.error.withOpacity(0.1),
                          ),
                          child: Text(
                            '${pourcentagePaye.toStringAsFixed(1)}% payé',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: pourcentagePaye >= 50 
                                  ? AppColors.success
                                  : pourcentagePaye >= 25 
                                      ? AppColors.warning
                                      : AppColors.error,
                            ),
                          ),
                        ),
                      ],
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
                size: 20,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentProgress(Map<String, dynamic> item, double pourcentagePaye, bool isExpanded) {
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
                  NumberFormat.currency(locale: 'fr_FR', symbol: '').format(item['montantTotal']),
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
                  NumberFormat.currency(locale: 'fr_FR', symbol: '').format(item['totalPaye']),
                  style: TextStyle(
                    fontSize: isExpanded ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: item['totalPaye'] > 0 ? AppColors.success : Colors.grey.shade600,
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
                  NumberFormat.currency(locale: 'fr_FR', symbol: '').format(item['montantDu']),
                  style: TextStyle(
                    fontSize: isExpanded ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Afficher la barre de progression
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
                '${pourcentagePaye.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: pourcentagePaye >= 50 
                      ? AppColors.success
                      : pourcentagePaye >= 25 
                          ? AppColors.warning
                          : AppColors.error,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pourcentagePaye / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: pourcentagePaye >= 50 
                      ? [AppColors.success, AppColors.successDark]
                      : pourcentagePaye >= 25 
                        ? [AppColors.warning, AppColors.warningDark]
                        : [AppColors.error, AppColors.errorDark],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ] else ...[
          // Version compacte de la barre de progression
          SizedBox(height: 6),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pourcentagePaye / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: pourcentagePaye >= 50 
                      ? [AppColors.success, AppColors.successDark]
                      : pourcentagePaye >= 25 
                        ? [AppColors.warning, AppColors.warningDark]
                        : [AppColors.error, AppColors.errorDark],
                  ),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailedInfo(Map<String, dynamic> item, double pourcentagePaye) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Taux de recouvrement',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(100 - pourcentagePaye).toStringAsFixed(1)}% restant',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnneeSelector() {
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

  Widget _buildStatistiquesGrid(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements) {
    final nombreAdherents = adherents.where((a) => a.estActif == true).length;
    final cotisationsAnnee = cotisations.where((c) => c.annee == anneeSelectionnee).toList();
    final paiementsAnnee = paiements.where((p) => p.annee == anneeSelectionnee).toList();

    final totalCotisations = cotisationsAnnee.fold<int>(0, (sum, c) => sum + c.montantAnnuel);
    final totalPayements = paiementsAnnee.fold<int>(0, (sum, p) => sum + p.montantVerse);
    final tauxRecouvrement = totalCotisations > 0 ? (totalPayements / totalCotisations * 100) : 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        Card(
          elevation: 2,
          color: Colors.blue[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue[200]!, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.people, size: 16, color: Colors.blue[700]),
                ),
                SizedBox(height: 4),
                Text(
                  '$nombreAdherents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Adhérents Actifs',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          color: Colors.green[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green[200]!, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.account_balance, size: 16, color: Colors.green[700]),
                ),
                SizedBox(height: 2),
                Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(totalCotisations)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Cotisations Annuelles',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          color: Colors.orange[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange[200]!, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.payments, size: 16, color: Colors.orange[700]),
                ),
                SizedBox(height: 2),
                Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalPayements)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Montant Collecté',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 2,
          color: Colors.purple[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.purple[200]!, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.trending_up, size: 18, color: Colors.purple[700]),
                ),
                SizedBox(height: 2),
                Text(
                  '${tauxRecouvrement.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[900],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Taux Recouvrement',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.purple[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsAppFAB(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements) {
    // Vérifier si nous sommes dans l'onglet "Retards" et s'il y a des adhérents en retard
    if (_tabController.index != 1) return SizedBox.shrink();
    
    final adherentsRetard = _getAdherentsRetard(adherents, cotisations, paiements);
    if (adherentsRetard.isEmpty) return SizedBox.shrink();

    return FloatingActionButton(
      onPressed: () => _envoyerMessagesWhatsApp(adherentsRetard),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Icon(Icons.message),
      tooltip: 'Envoyer un message WhatsApp à tous les adhérents en retard (${adherentsRetard.length})',
    );
  }

  List<Map<String, dynamic>> _getAdherentsRetard(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements) {
    final adherentsRetard = <Map<String, dynamic>>[];

    for (var adherent in adherents.where((a) => a.estActif == true)) {
      final cotisationsAnnee = cotisations.where(
            (c) => c.adherentId == adherent.id && c.annee == anneeSelectionnee,
      ).toList();

      if (cotisationsAnnee.isNotEmpty) {
        final cotisationAnnee = cotisationsAnnee.first;
        final paiementAnnee = paiements.where(
              (p) => p.adherentId == adherent.id && p.annee == anneeSelectionnee,
        ).toList();

        final totalPaye = paiementAnnee.fold<int>(0, (sum, p) => sum + p.montantVerse);
        final montantDu = cotisationAnnee.montantAnnuel;

        if (totalPaye < montantDu) {
          adherentsRetard.add({
            'adherent': adherent,
            'montantDu': montantDu - totalPaye,
            'totalPaye': totalPaye,
            'montantTotal': montantDu,
          });
        }
      }
    }

    return adherentsRetard;
  }

  Future<void> _envoyerMessagesWhatsApp(List<Map<String, dynamic>> adherentsRetard) async {
    for (var item in adherentsRetard) {
      final adherent = item['adherent'] as Adherent;
      final montantTotal = item['montantTotal'] as int;
      final totalPaye = item['totalPaye'] as int;
      final montantDu = item['montantDu'] as int;
      
      // Générer le message personnalisé
      final message = _genererMessageWhatsApp(adherent, montantTotal, totalPaye, montantDu);
      
      // Envoyer le message WhatsApp
      await _envoyerMessageWhatsApp(adherent.telephone, message);
      
      // Petite pause entre les envois pour éviter les limitations
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  String _genererMessageWhatsApp(Adherent adherent, int montantTotal, int totalPaye, int montantDu) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');
    
    return '''
📢 *Rappel de cotisation - Fondation Okoukro*

Cher(ère) *${adherent.prenom} ${adherent.nom}*,

Voici un récapitulatif de votre situation de cotisation pour l'année *$anneeSelectionnee* :

💰 *Montant total de la cotisation :* ${formatCurrency.format(montantTotal)}
✅ *Montant déjà payé :* ${formatCurrency.format(totalPaye)}
⏳ *Reste à payer :* ${formatCurrency.format(montantDu)}

📊 *Taux de paiement :* ${(totalPaye / montantTotal * 100).toStringAsFixed(1)}%

Nous vous remercions pour votre contribution à notre association. Pour régulariser votre situation, merci de nous contacter.

🙏 *Fondation Okoukro - Ensemble pour l'avenir*
    ''';
  }

  Future<void> _envoyerMessageWhatsApp(String telephone, String message) async {
    try {
      // Nettoyer le numéro de téléphone (supprimer les espaces, tirets, etc.)
      String cleanPhone = telephone.replaceAll(RegExp(r'[^\d+]'), '');
      
      // S'assurer que le numéro commence avec le code pays (+225 pour la Côte d'Ivoire)
      if (!cleanPhone.startsWith('+')) {
        cleanPhone = '+225$cleanPhone';
      }
      
      // Encoder le message pour l'URL
      String encodedMessage = Uri.encodeComponent(message);
      
      // Créer l'URL WhatsApp
      final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';
      
      // Essayer de lancer WhatsApp directement
      final uri = Uri.parse(whatsappUrl);
      await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
      );
      
      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message WhatsApp envoyé à $cleanPhone'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      // Vérifier si nous sommes sur un émulateur/simulateur
      bool isEmulator = false;
      
      if (e.toString().contains('Unable to establish connection') || 
          e.toString().contains('unavailable') ||
          e.toString().contains('ActivityNotFoundError')) {
        isEmulator = true;
      }
      
      String errorMessage = isEmulator 
          ? 'WhatsApp n\'est pas disponible sur l\'émulateur. Sur un appareil réel, le message serait envoyé.'
          : 'Impossible de se connecter à WhatsApp. Vérifiez que l\'application est installée.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: isEmulator ? Colors.orange : Colors.red,
          duration: Duration(seconds: isEmulator ? 4 : 3),
          action: isEmulator ? SnackBarAction(
            label: 'Copier message',
            textColor: Colors.white,
            onPressed: () => _copierMessageDansPressePapiers(message),
          ) : SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _copierMessageDansPressePapiers(String message) async {
    // Importer flutter/services si nécessaire
    await Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message copié dans le presse-papiers'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _rafraichirDonnees() async {
    await ref.read(adherentProvider.notifier).loadAdherents();
    await ref.read(cotisationProvider.notifier).loadCotisations();
    await ref.read(paiementProvider.notifier).loadPaiements();
    await ref.read(beneficeProvider.notifier).loadBenefices();
  }
}
