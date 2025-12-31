import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/paiement_provider.dart';
import '../providers/adherent_provider.dart';
import '../models/paiement.dart';
import '../models/adherent.dart';

class ListePaiementsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ListePaiementsScreen> createState() => _ListePaiementsScreenState();
}

class _ListePaiementsScreenState extends ConsumerState<ListePaiementsScreen> {
  String _selectedFilter = 'Tous';
  int? _selectedAnnee;
  String? _selectedAdherentId;
  List<Adherent> _adherents = [];

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
    if (adherentsAsync.hasValue) {
      setState(() {
        _adherents = adherentsAsync.value!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paiementsAsync = ref.watch(paiementProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Historique des Paiements',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: paiementsAsync.when(
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Erreur de chargement', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 8),
                      Text(error.toString(), textAlign: TextAlign.center),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (paiements) {
                final filteredPaiements = _filterPaiements(paiements);
                
                if (filteredPaiements.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Aucun paiement trouvé',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Effectuez des paiements pour voir l\'historique',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredPaiements.length,
                  itemBuilder: (context, index) {
                    final paiement = filteredPaiements[index];
                    final adherent = _adherents.firstWhere(
                      (a) => a.id == paiement.adherentId,
                      orElse: () => _adherents.isEmpty 
                        ? Adherent(nom: '', prenom: '', telephone: '', montantAnnuelContribution: 0)
                        : _adherents.first,
                    );
                    return _buildPaiementCard(paiement, adherent);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: InputDecoration(
                    labelText: 'Filtrer par',
                    prefixIcon: Icon(Icons.filter_list),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: [
                    DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                    DropdownMenuItem(value: 'Annee', child: Text('Année')),
                    DropdownMenuItem(value: 'Adherent', child: Text('Adhérent')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                      _selectedAnnee = null;
                      _selectedAdherentId = null;
                    });
                  },
                ),
              ),
              SizedBox(width: 12),
              if (_selectedFilter == 'Annee') ...[
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedAnnee,
                    decoration: InputDecoration(
                      labelText: 'Année',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _getAnnees().map((annee) {
                      return DropdownMenuItem(value: annee, child: Text('$annee'));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAnnee = value;
                      });
                    },
                  ),
                ),
              ] else if (_selectedFilter == 'Adherent') ...[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAdherentId,
                    decoration: InputDecoration(
                      labelText: 'Adhérent',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _adherents.map((adherent) {
                      return DropdownMenuItem(
                        value: adherent.id,
                        child: Text(adherent.nomComplet),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAdherentId = value;
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
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
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.payment,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adherent.nomComplet,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Année ${paiement.annee}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
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
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(paiement.datePaiement),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      paiement.methodeFormate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                if (paiement.notes != null && paiement.notes!.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      paiement.notes!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
