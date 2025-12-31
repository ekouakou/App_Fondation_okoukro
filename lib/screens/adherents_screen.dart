import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/adherent_provider.dart';
import '../models/adherent.dart';
import '../utils/constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/empty_state_widget.dart';
import 'cotisations_screen.dart';

class AdherentsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<AdherentsScreen> createState() => _AdherentsScreenState();
}

class _AdherentsScreenState extends ConsumerState<AdherentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adherentsAsync = ref.watch(adherentProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
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
                      onPressed: () => ref.read(adherentProvider.notifier).loadAdherents(),
                      child: Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (adherents) => _buildAdherentsList(adherents),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAdherentDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un adhérent...',
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
      onRefresh: () => ref.read(adherentProvider.notifier).loadAdherents(),
      child: ListView.builder(
        itemCount: filteredAdherents.length,
        itemBuilder: (context, index) {
          final adherent = filteredAdherents[index];
          return _buildAdherentCard(adherent);
        },
      ),
    );
  }

  Widget _buildAdherentCard(Adherent adherent) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: adherent.estActif ? Colors.green : Colors.grey,
          child: adherent.photoUrl.isNotEmpty
              ? ClipOval(
            child: Image.network(
              adherent.photoUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.person, color: Colors.white);
              },
            ),
          )
              : Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          adherent.nomComplet,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: adherent.estActif ? Colors.black87 : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(adherent.telephone),
            SizedBox(height: 4),
            Text(
              'Adhésion: ${DateFormat('dd MMM yyyy').format(adherent.dateAdhesion)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!adherent.estActif)
              Chip(
                label: Text('Inactif'),
                backgroundColor: Colors.red.withOpacity(0.1),
                labelStyle: TextStyle(color: Colors.red, fontSize: 12),
              ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, adherent),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('Voir'),
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
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(adherent.estActif ? Icons.block : Icons.check_circle),
                      SizedBox(width: 8),
                      Text(adherent.estActif ? 'Désactiver' : 'Activer'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'add_cotisation',
                  child: Row(
                    children: [
                      Icon(Icons.money),
                      SizedBox(width: 8),
                      Text('Ajouter une cotisation'),
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
        onTap: () => _viewAdherentDetails(adherent),
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
    showDialog(
      context: context,
      builder: (context) => AdherentFormScreen(),
    ).then((_) {
      ref.read(adherentProvider.notifier).loadAdherents();
    });
  }

  void _showEditAdherentDialog(Adherent adherent) {
    showDialog(
      context: context,
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
    showDialog(
      context: context,
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

class AdherentDetailsScreen extends ConsumerWidget {
  final Adherent adherent;

  const AdherentDetailsScreen({Key? key, required this.adherent}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(adherent.nomComplet),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AdherentFormScreen(adherent: adherent),
              ).then((_) {
                // Rafraîchir les données après modification
                ref.refresh(adherentProvider);
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            SizedBox(height: 24),
            _buildInformationsSection(context),
            SizedBox(height: 24),
            _buildCotisationsSection(context),
            SizedBox(height: 24),
            _buildPaiementsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[300],
              child: adherent.photoUrl.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  adherent.photoUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              )
                  : Icon(Icons.person, size: 40, color: Colors.white),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(adherent.estActif ? 'Actif' : 'Inactif'),
                    backgroundColor: adherent.estActif ? Colors.green : Colors.red,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                ],
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
                _buildInfoRow('Téléphone', adherent.telephone),
                _buildInfoRow('Email', adherent.email),
                _buildInfoRow('Adresse', adherent.adresse),
                _buildInfoRow(
                  'Date d\'adhésion',
                  DateFormat('dd MMMM yyyy').format(adherent.dateAdhesion),
                ),
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
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Non renseigné',
              style: TextStyle(color: value.isNotEmpty ? null : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCotisationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cotisations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Section à implémenter'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaiementsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paiements',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('Section à implémenter'),
          ),
        ),
      ],
    );
  }
}

class AdherentFormScreen extends ConsumerStatefulWidget {
  final Adherent? adherent;

  const AdherentFormScreen({Key? key, this.adherent}) : super(key: key);

  @override
  ConsumerState<AdherentFormScreen> createState() => _AdherentFormScreenState();
}

class _AdherentFormScreenState extends ConsumerState<AdherentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _contributionController = TextEditingController();
  DateTime? _dateAdhesion;

  @override
  void initState() {
    super.initState();
    if (widget.adherent != null) {
      _nomController.text = widget.adherent!.nom;
      _prenomController.text = widget.adherent!.prenom;
      _telephoneController.text = widget.adherent!.telephone;
      _emailController.text = widget.adherent!.email;
      _adresseController.text = widget.adherent!.adresse;
      _contributionController.text = widget.adherent!.montantAnnuelContribution.toString();
      _dateAdhesion = widget.adherent!.dateAdhesion;
    } else {
      _dateAdhesion = DateTime.now(); // Date par défaut = aujourd'hui
      _contributionController.text = '12000'; // Valeur par défaut
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.adherent == null ? 'Nouvel adhérent' : 'Modifier l\'adhérent'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(labelText: 'Nom *'),
                validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _prenomController,
                decoration: InputDecoration(labelText: 'Prénom *'),
                validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _telephoneController,
                decoration: InputDecoration(labelText: 'Téléphone *'),
                validator: (value) => value?.isEmpty == true ? 'Champ obligatoire' : null,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _adresseController,
                decoration: InputDecoration(labelText: 'Adresse'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _contributionController,
                decoration: InputDecoration(
                  labelText: 'Contribution annuelle (FCFA) *',
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Champ obligatoire';
                  final montant = int.tryParse(value!);
                  if (montant == null) return 'Montant invalide';
                  if (montant < 1000) return 'Le montant minimum est de 1000 FCFA';
                  return null;
                },
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Text(
                        'Date d\'adhésion: ${DateFormat('dd MMM yyyy').format(_dateAdhesion!)}',
                        style: TextStyle(fontSize: 16),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
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
          onPressed: _saveAdherent,
          child: Text('Enregistrer'),
        ),
      ],
    );
  }

  void _saveAdherent() {
    if (_formKey.currentState?.validate() == true) {
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
            content: Text('Adhérent ajouté avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ref.read(adherentProvider.notifier).updateAdherent(adherent);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Adhérent modifié avec succès!'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateAdhesion ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)), // Permettre les dates futures jusqu'à 1 an
    );
    if (picked != null && picked != _dateAdhesion) {
      setState(() {
        _dateAdhesion = picked;
      });
    }
  }
}