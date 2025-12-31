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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur d'année
          _buildAnneeSelector(),
          SizedBox(height: 16),

          // Cartes de statistiques
          _buildStatistiquesGrid(adherents.cast<Adherent>(), cotisations.cast<Cotisation>(), paiements.cast<Paiement>()),
          SizedBox(height: 24),

          // Résumé des activités
          _buildActivitiesSection(adherents.cast<Adherent>(), cotisations.cast<Cotisation>(), paiements.cast<Paiement>()),
          SizedBox(height: 24),

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
                Text('$nombreAdherents'),
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
                Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalCotisations)}'),
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
                Text('${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(totalPayements)}'),
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
                Text('${tauxRecouvrement.toStringAsFixed(1)}%'),
                Text('Taux Recouvrement', style: Theme.of(context).textTheme.bodySmall),
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
        Text(
          'Adhérents en Retard (${adherentsRetard.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Column(
            children: adherentsRetard.map((item) {
              final adherent = item['adherent'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.warning, color: Colors.white),
                ),
                title: Text('${adherent['nom']} ${adherent['prenom']}'),
                subtitle: Text('Payé: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(item['totalPaye'])} / ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(item['montantTotal'])}'),
                trailing: Text(
                  'Reste: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA').format(item['montantDu'])}',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
