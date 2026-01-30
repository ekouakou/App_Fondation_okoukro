import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/adherent.dart';
import '../models/cotisation.dart';
import '../models/paiement.dart';
import '../models/benefice.dart';
import '../providers/adherent_provider.dart';
import '../providers/cotisation_provider.dart';
import '../providers/paiement_provider.dart';
import '../providers/benefice_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int anneeSelectionnee = DateTime.now().year;

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
          SizedBox(height: 20),

          // Résumé des activités
          _buildActivitiesSection(adherents.cast<Adherent>(), cotisations.cast<Cotisation>(), paiements.cast<Paiement>()),
          SizedBox(height: 20),

          // Adhérents en retard
          _buildRetardSection(adherents.cast<Adherent>(), cotisations.cast<Cotisation>(), paiements.cast<Paiement>()),
        ],
      ),
    );
  }

  Widget _buildAnneeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Année: $anneeSelectionnee',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                  child: Icon(Icons.people, size: 24, color: Colors.blue[700]),
                ),
                SizedBox(height: 8),
                Text(
                  '$nombreAdherents',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 4),
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
                  child: Icon(Icons.account_balance, size: 24, color: Colors.green[700]),
                ),
                SizedBox(height: 8),
                Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalCotisations)}',
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
                  child: Icon(Icons.payments, size: 24, color: Colors.orange[700]),
                ),
                SizedBox(height: 8),
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
                  child: Icon(Icons.trending_up, size: 24, color: Colors.purple[700]),
                ),
                SizedBox(height: 8),
                Text(
                  '${tauxRecouvrement.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
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

  Widget _buildActivitiesSection(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements) {
    final activities = <Map<String, dynamic>>[];

    // Ajouter les paiements récents
    for (var paiement in paiements.take(5)) {
      activities.add({
        'type': 'paiement',
        'title': 'Paiement reçu',
        'description': '${paiement.montantVerse} FCFA',
        'date': paiement.datePaiement,
        'icon': Icons.payment,
        'color': Colors.green,
      });
    }

    // Ajouter les nouvelles cotisations
    for (var cotisation in cotisations.take(3)) {
      activities.add({
        'type': 'cotisation',
        'title': 'Nouvelle cotisation',
        'description': '${cotisation.montantAnnuel} FCFA',
        'date': cotisation.dateModification,
        'icon': Icons.account_balance,
        'color': Colors.blue,
      });
    }

    // Trier par date
    activities.sort((a, b) => b['date'].compareTo(a['date']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activités Récentes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        if (activities.isEmpty)
          EmptyStateWidget(
            icon: Icons.history,
            title: 'Aucune activité',
            subtitle: 'Aucune activité récente à afficher',
          )
        else
          ...activities.map((activity) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: activity['color'],
                child: Icon(activity['icon'], color: Colors.white),
              ),
              title: Text(activity['title']),
              subtitle: Text(activity['description']),
              trailing: Text(
                DateFormat('dd MMM', 'fr').format(activity['date']),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildRetardSection(List<Adherent> adherents, List<Cotisation> cotisations, List<Paiement> paiements) {
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

    if (adherentsRetard.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[400]!, Colors.red[600]!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Adhérents en Retard (${adherentsRetard.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[200]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: adherentsRetard.map((item) {
              final adherent = item['adherent'];
              final pourcentagePaye = (item['totalPaye'] / item['montantTotal'] * 100);
              
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person_outline, color: Colors.red[700], size: 20),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${adherent.nom} ${adherent.prenom}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Payé: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(item['totalPaye'])} / ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(item['montantTotal'])}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Reste:',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(item['montantDu'])}',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pourcentagePaye / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: pourcentagePaye >= 50 
                                ? [Colors.green[400]!, Colors.green[600]!]
                                : pourcentagePaye >= 25 
                                  ? [Colors.orange[400]!, Colors.orange[600]!]
                                  : [Colors.red[400]!, Colors.red[600]!],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${pourcentagePaye.toStringAsFixed(1)}% payé',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${(100 - pourcentagePaye).toStringAsFixed(1)}% restant',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _rafraichirDonnees() async {
    await ref.read(adherentProvider.notifier).loadAdherents();
    await ref.read(cotisationProvider.notifier).loadCotisations();
    await ref.read(paiementProvider.notifier).loadPaiements();
    await ref.read(beneficeProvider.notifier).loadBenefices();
  }
}
