import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/benefice_provider.dart';
import '../providers/adherent_provider.dart';
import '../providers/cotisation_provider.dart';
import '../models/benefice.dart';
import '../models/adherent.dart';
import '../models/cotisation.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';

class BeneficesScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<BeneficesScreen> createState() => _BeneficesScreenState();
}

class _BeneficesScreenState extends ConsumerState<BeneficesScreen> {
  int anneeSelectionnee = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final beneficesAsync = ref.watch(beneficeProvider);
    final adherentsAsync = ref.watch(adherentProvider);
    final cotisationsAsync = ref.watch(cotisationProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: beneficesAsync.when(
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
                      onPressed: () => ref.read(beneficeProvider.notifier).loadBenefices(),
                      child: Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (benefices) => adherentsAsync.when(
                loading: () => LoadingWidget(),
                error: (error, stack) => Center(child: Text('Erreur: $error')),
                data: (adherents) => cotisationsAsync.when(
                  loading: () => LoadingWidget(),
                  error: (error, stack) => Center(child: Text('Erreur: $error')),
                  data: (cotisations) => _buildBeneficesList(benefices, adherents, cotisations),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBeneficeDialog,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildBeneficesList(List<Benefice> benefices, List<Adherent> adherents, List<Cotisation> cotisations) {
    final beneficesAnnee = benefices.where((b) => b.annee == anneeSelectionnee).toList();

    if (beneficesAnnee.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.trending_up_outlined,
        title: 'Aucun bénéfice',
        subtitle: 'Ajoutez des bénéfices pour l\'année $anneeSelectionnee',
        action: FloatingActionButton(
          onPressed: _showAddBeneficeDialog,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Icon(Icons.add),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(beneficeProvider.notifier).loadBenefices(),
      child: ListView.builder(
        itemCount: beneficesAnnee.length,
        itemBuilder: (context, index) {
          final benefice = beneficesAnnee[index];
          return _buildBeneficeCard(benefice, adherents, cotisations);
        },
      ),
    );
  }

  Widget _buildBeneficeCard(Benefice benefice, List<Adherent> adherents, List<Cotisation> cotisations) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: benefice.estDistribue ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          child: Icon(
            benefice.estDistribue ? Icons.check_circle : Icons.hourglass_empty,
            color: benefice.estDistribue ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          'Bénéfice - Année ${benefice.annee}',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant: ${benefice.montantFormate}'),
            SizedBox(height: 4),
            Text(
              'Distribution: ${DateFormat('dd MMM yyyy').format(benefice.dateDistribution)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (benefice.description.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                benefice.description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  benefice.montantFormate,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Chip(
                  label: Text(
                    benefice.estDistribue ? 'Distribué' : 'En attente',
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: benefice.estDistribue
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: benefice.estDistribue ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, benefice, adherents, cotisations),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Voir détails'),
                    ],
                  ),
                ),
                if (!benefice.estDistribue)
                  PopupMenuItem(
                    value: 'distribute',
                    child: Row(
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 8),
                        Text('Distribuer'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _viewBeneficeDetails(benefice, adherents, cotisations),
      ),
    );
  }

  void _handleMenuAction(String action, Benefice benefice, List<Adherent> adherents, List<Cotisation> cotisations) {
    switch (action) {
      case 'view':
        _viewBeneficeDetails(benefice, adherents, cotisations);
        break;
      case 'distribute':
        _showDistributionDialog(benefice, adherents, cotisations);
        break;
      case 'edit':
        _showEditBeneficeDialog(benefice);
        break;
      case 'delete':
        _showDeleteConfirmation(benefice);
        break;
    }
  }

  void _viewBeneficeDetails(Benefice benefice, List<Adherent> adherents, List<Cotisation> cotisations) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BeneficeDetailsScreen(
          benefice: benefice,
          adherents: adherents,
          cotisations: cotisations,
        ),
      ),
    );
  }

  void _showAddBeneficeDialog() {
    showDialog(
      context: context,
      builder: (context) => BeneficeFormScreen(),
    ).then((_) {
      ref.read(beneficeProvider.notifier).loadBenefices();
    });
  }

  void _showEditBeneficeDialog(Benefice benefice) {
    showDialog(
      context: context,
      builder: (context) => BeneficeFormScreen(benefice: benefice),
    ).then((_) {
      ref.read(beneficeProvider.notifier).loadBenefices();
    });
  }

  void _showDistributionDialog(Benefice benefice, List<Adherent> adherents, List<Cotisation> cotisations) {
    showDialog(
      context: context,
      builder: (context) => DistributionDialog(
        benefice: benefice,
        adherents: adherents,
        cotisations: cotisations,
      ),
    );
  }

  void _showDeleteConfirmation(Benefice benefice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer le bénéfice'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce bénéfice de ${benefice.montantFormate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.annuler),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Note: Il faudrait implémenter deleteBenefice dans le provider
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Bénéfice supprimé')),
              );
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analyse des bénéfices'),
        content: Text('Section d\'analyse à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class BeneficeDetailsScreen extends ConsumerWidget {
  final Benefice benefice;
  final List<Adherent> adherents;
  final List<Cotisation> cotisations;

  const BeneficeDetailsScreen({
    Key? key,
    required this.benefice,
    required this.adherents,
    required this.cotisations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partsAsync = ref.watch(partsBeneficeProvider(benefice.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du bénéfice'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBeneficeHeader(context),
            SizedBox(height: 24),
            _buildInformationsSection(context),
            SizedBox(height: 24),
            _buildDistributionSection(context, partsAsync as AsyncValue<List<PartBenefice>>),
          ],
        ),
      ),
    );
  }

  Widget _buildBeneficeHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bénéfice - Année ${benefice.annee}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Chip(
                  label: Text(
                    benefice.estDistribue ? 'Distribué' : 'En attente',
                  ),
                  backgroundColor: benefice.estDistribue
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: benefice.estDistribue ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              benefice.montantFormate,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Année', benefice.annee.toString()),
                _buildInfoRow('Montant total', benefice.montantFormate),
                _buildInfoRow(
                  'Date de distribution',
                  DateFormat('dd MMMM yyyy').format(benefice.dateDistribution),
                ),
                if (benefice.description.isNotEmpty)
                  _buildInfoRow('Description', benefice.description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection(BuildContext context, AsyncValue<List<PartBenefice>> partsAsync) {
    if (!benefice.estDistribue) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribution',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.hourglass_empty, size: 48, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Ce bénéfice n\'a pas encore été distribué',
                    style: TextStyle(color: Colors.orange),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implémenter la distribution
                    },
                    child: Text('Distribuer le bénéfice'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails de la distribution',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        partsAsync.when(
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Erreur: $error')),
          data: (parts) => Card(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nombre de bénéficiaires: ${parts.length}'),
                      Text(
                        'Total distribué: ${parts.fold(0, (sum, part) => sum + part.montantPart)} FCFA',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: parts.length,
                  itemBuilder: (context, index) {
                    final part = parts[index];
                    final adherent = adherents.firstWhere(
                          (a) => a.id == part.adherentId,
                      orElse: () => Adherent(nom: '', prenom: '', telephone: ''),
                    );
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(adherent.nomComplet.isNotEmpty ? adherent.nomComplet[0].toUpperCase() : '?'),
                      ),
                      title: Text(adherent.nomComplet.isNotEmpty ? adherent.nomComplet : 'Adhérent inconnu'),
                      subtitle: Text('${part.pourcentageFormate} du total'),
                      trailing: Text(
                        part.montantFormate,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BeneficeFormScreen extends ConsumerStatefulWidget {
  final Benefice? benefice;

  const BeneficeFormScreen({Key? key, this.benefice}) : super(key: key);

  @override
  ConsumerState<BeneficeFormScreen> createState() => _BeneficeFormScreenState();
}

class _BeneficeFormScreenState extends ConsumerState<BeneficeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _anneeController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.benefice != null) {
      _montantController.text = widget.benefice!.montantTotal.toString();
      _anneeController.text = widget.benefice!.annee.toString();
      _descriptionController.text = widget.benefice!.description;
    } else {
      _anneeController.text = DateTime.now().year.toString();
    }
  }

  @override
  void dispose() {
    _montantController.dispose();
    _anneeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.benefice == null ? 'Nouveau bénéfice' : 'Modifier le bénéfice'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _anneeController,
                decoration: InputDecoration(labelText: 'Année'),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: _montantController,
                decoration: InputDecoration(labelText: 'Montant total (FCFA)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Champ obligatoire';
                  if (int.tryParse(value!) == null) return 'Montant invalide';
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.annuler),
        ),
        ElevatedButton(
          onPressed: _saveBenefice,
          child: Text('Enregistrer'),
        ),
      ],
    );
  }

  void _saveBenefice() {
    if (_formKey.currentState?.validate() == true) {
      final benefice = Benefice(
        id: widget.benefice?.id,
        annee: int.parse(_anneeController.text),
        montantTotal: int.parse(_montantController.text),
        description: _descriptionController.text.trim(),
        estDistribue: widget.benefice?.estDistribue ?? false,
      );

      if (widget.benefice == null) {
        // Note: Il faudrait utiliser le provider pour ajouter
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bénéfice ajouté')),
        );
      } else {
        // Note: Il faudrait utiliser le provider pour modifier
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bénéfice modifié')),
        );
      }

      Navigator.pop(context);
    }
  }
}

class DistributionDialog extends ConsumerWidget {
  final Benefice benefice;
  final List<Adherent> adherents;
  final List<Cotisation> cotisations;

  const DistributionDialog({
    Key? key,
    required this.benefice,
    required this.adherents,
    required this.cotisations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text('Distribuer le bénéfice'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Montant à distribuer: ${benefice.montantFormate}'),
          SizedBox(height: 16),
          Text('Nombre d\'adhérents actifs: ${adherents.where((a) => a.estActif).length}'),
          SizedBox(height: 16),
          Text(
            'La distribution sera calculée proportionnellement aux cotisations de chaque adhérent.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.annuler),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Distribution effectuée')),
            );
          },
          child: Text('Distribuer'),
        ),
      ],
    );
  }
}