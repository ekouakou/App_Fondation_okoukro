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

class CotisationsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CotisationsScreen> createState() => _CotisationsScreenState();
}

class _CotisationsScreenState extends ConsumerState<CotisationsScreen> {
  int anneeSelectionnee = DateTime.now().year;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cotisation.estSoldee 
              ? Colors.green.withOpacity(0.1) 
              : cotisation.montantPaye > 0 
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
          child: Icon(
            cotisation.estSoldee 
                ? Icons.check_circle 
                : cotisation.montantPaye > 0 
                    ? Icons.pending
                    : Icons.money_off,
            color: cotisation.estSoldee 
                ? Colors.green 
                : cotisation.montantPaye > 0 
                    ? Colors.orange
                    : Colors.red,
          ),
        ),
        title: Text('Année ${cotisation.annee}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adhérent: ${adherent.nomComplet}'),
            SizedBox(height: 4),
            Text('Contribution: ${cotisation.montantFormate}'),
            SizedBox(height: 4),
            Row(
              children: [
                Text('Payé: ${cotisation.montantPayeFormate}'),
                SizedBox(width: 8),
                Text('(${cotisation.pourcentagePaye.toStringAsFixed(1)}%)'),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Reste: ${cotisation.resteFormate}',
              style: TextStyle(
                color: cotisation.resteAPayer > 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Statut: ${cotisation.statut}',
              style: TextStyle(
                color: cotisation.estSoldee 
                    ? Colors.green 
                    : cotisation.montantPaye > 0 
                        ? Colors.orange
                        : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Modifié le: ${DateFormat('dd MMM yyyy').format(cotisation.dateModification)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (cotisation.motifModification != null) ...[
              SizedBox(height: 4),
              Text(
                'Motif: ${cotisation.motifModification}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              cotisation.statut,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cotisation.estSoldee 
                    ? Colors.green 
                    : cotisation.montantPaye > 0 
                        ? Colors.orange
                        : Colors.red,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            if (!cotisation.estSoldee)
              ElevatedButton(
                onPressed: () => _showPaymentDialog(cotisation, adherent),
                child: Text('Payer'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size(0, 24),
                ),
              ),
          ],
        ),
        onTap: () => _showCotisationDetails(cotisation, adherent),
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

  void _showCotisationDetails(Cotisation cotisation, Adherent adherent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails de la cotisation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adhérent: ${adherent.nomComplet}'),
            Text('Téléphone: ${adherent.telephone}'),
            SizedBox(height: 16),
            Text('Année: ${cotisation.annee}'),
            Text('Contribution annuelle: ${cotisation.montantFormate}'),
            Text('Montant payé: ${cotisation.montantPayeFormate}'),
            Text('Reste à payer: ${cotisation.resteFormate}'),
            Text('Pourcentage payé: ${cotisation.pourcentagePaye.toStringAsFixed(1)}%'),
            Text('Statut: ${cotisation.statut}'),
            Text('Date de modification: ${DateFormat('dd MMM yyyy').format(cotisation.dateModification)}'),
            if (cotisation.motifModification != null)
              Text('Motif: ${cotisation.motifModification}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          if (!cotisation.estSoldee)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showPaymentDialog(cotisation, adherent);
              },
              child: Text('Effectuer un paiement'),
            ),
        ],
      ),
    );
  }

  void _showAddCotisationDialog() {
    showDialog(
      context: context,
      builder: (context) => CotisationFormScreen(),
    ).then((_) {
      ref.read(cotisationProvider.notifier).loadCotisations();
    });
  }

  void _showEditCotisationDialog(Cotisation cotisation, Adherent adherent) {
    showDialog(
      context: context,
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

class _CotisationFormScreenState extends ConsumerState<CotisationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _anneeController = TextEditingController();
  final _motifController = TextEditingController();
  final _montantController = TextEditingController();
  
  Adherent? _selectedAdherent;
  List<Adherent> _adherents = [];
  int _montantAnnuel = 0;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.cotisation == null ? 'Nouvelle cotisation' : 'Modifier la cotisation'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sélection de l'adhérent
                if (widget.adherent == null) ...[
                  DropdownButtonFormField<Adherent>(
                    value: _selectedAdherent,
                    decoration: InputDecoration(
                      labelText: 'Adhérent *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: _adherents.map((adherent) {
                      return DropdownMenuItem<Adherent>(
                        value: adherent,
                        child: Text(adherent.nomComplet),
                      );
                    }).toList(),
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
                  SizedBox(height: 16),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[600]),
                        SizedBox(width: 12),
                        Text('Adhérent: ${widget.adherent!.nomComplet}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                
                // Champ année
                TextFormField(
                  controller: _anneeController,
                  decoration: InputDecoration(
                    labelText: 'Année *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
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
                SizedBox(height: 16),
                
                // Champ montant annuel (modifiable)
                TextFormField(
                  controller: _montantController,
                  decoration: InputDecoration(
                    labelText: 'Montant annuel (FCFA) *',
                    prefixIcon: Icon(Icons.money),
                    hintText: 'Entrez le montant de la cotisation annuelle',
                  ),
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
                SizedBox(height: 16),
                
                // Champ motif (pour création et modification)
                TextFormField(
                  controller: _motifController,
                  decoration: InputDecoration(
                    labelText: widget.cotisation == null ? 'Motif de création' : 'Motif de modification',
                    prefixIcon: Icon(Icons.edit_note),
                    hintText: widget.cotisation == null 
                        ? 'Entrez la raison de cette cotisation' 
                        : 'Entrez la raison de la modification',
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (widget.cotisation == null && (value?.isEmpty == true || value?.trim() == '')) {
                      return 'Le motif est obligatoire pour la création';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.annuler),
        ),
        ElevatedButton(
          onPressed: _saveCotisation,
          child: Text(widget.cotisation == null ? 'Enregistrer' : 'Modifier'),
        ),
      ],
    );
  }

  void _saveCotisation() {
    if (_formKey.currentState?.validate() == true && _selectedAdherent != null) {
      final adherentId = _selectedAdherent!.id;
      final annee = int.parse(_anneeController.text);
      final montantAnnuel = int.parse(_montantController.text);
      final motif = _motifController.text.trim();

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
            content: Text('Cotisation créée avec succès! Vous pouvez maintenant enregistrer les paiements.'),
            backgroundColor: Colors.green,
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
            content: Text('Cotisation modifiée avec succès!'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      Navigator.pop(context);
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
