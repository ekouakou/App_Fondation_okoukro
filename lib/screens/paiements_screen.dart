import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/adherent_provider.dart';
import '../providers/cotisation_provider.dart';
import '../providers/paiement_provider.dart';
import '../models/adherent.dart';
import '../models/cotisation.dart';
import '../models/paiement.dart';
import 'liste_paiements_screen.dart';

class PaiementsScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<PaiementsScreen> createState() => _PaiementsScreenState();
}

class _PaiementsScreenState extends ConsumerState<PaiementsScreen> {
  String? _selectedAdherentId;  // Changed: Store ID instead of object
  String? _selectedCotisationId;  // Changed: Store ID instead of object
  List<Adherent> _adherents = [];
  List<Cotisation> _cotisations = [];

  // Helper getters to retrieve objects by ID
  Adherent? get _selectedAdherent =>
      _selectedAdherentId == null ? null : _adherents.firstWhere(
            (a) => a.id == _selectedAdherentId,
        orElse: () => _adherents.first,
      );

  Cotisation? get _selectedCotisation =>
      _selectedCotisationId == null ? null : _cotisations.firstWhere(
            (c) => c.id == _selectedCotisationId,
        orElse: () => _cotisations.first,
      );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await ref.read(adherentProvider.notifier).loadAdherents();
    await ref.read(cotisationProvider.notifier).loadCotisations();

    final adherentsAsync = ref.read(adherentProvider);
    final cotisationsAsync = ref.read(cotisationProvider);

    if (adherentsAsync.hasValue && cotisationsAsync.hasValue) {
      setState(() {
        // Filtrer les adhérents pour éviter les doublons en utilisant une Map
        final uniqueAdherents = <String, Adherent>{};
        for (final adherent in adherentsAsync.value!) {
          if (adherent.id.isNotEmpty) {
            uniqueAdherents[adherent.id] = adherent;
          }
        }
        _adherents = uniqueAdherents.values.toList();

        // Trier par nom pour plus de cohérence
        _adherents.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));

        _cotisations = cotisationsAsync.value!;

        // Réinitialiser la sélection si elle n'existe plus
        if (_selectedAdherentId != null && !_adherents.any((a) => a.id == _selectedAdherentId)) {
          _selectedAdherentId = null;
          _selectedCotisationId = null;
        }
        if (_selectedCotisationId != null && !_cotisations.any((c) => c.id == _selectedCotisationId)) {
          _selectedCotisationId = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Nouveau Paiement',
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
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListePaiementsScreen()),
              );
            },
            tooltip: 'Voir l\'historique des paiements',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildAdherentCard(),
            if (_selectedAdherent != null) ...[
              SizedBox(height: 16),
              _buildCotisationCard(),
              if (_selectedCotisation != null) ...[
                SizedBox(height: 16),
                _buildPaymentCard(),
                SizedBox(height: 24),
                _buildPayButton(),
              ],
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'paiement_history_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ListePaiementsScreen()),
          );
        },
        icon: Icon(Icons.history),
        label: Text('Historique'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.payment,
            color: Theme.of(context).primaryColor,
            size: 32,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enregistrer un paiement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Selectionnez un adherent et sa cotisation',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdherentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '1. Choisissez un adherent',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _selectedAdherentId,
              decoration: InputDecoration(
                hintText: 'Choisir un adherent',
                prefixIcon: Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _adherents.map((adherent) {
                return DropdownMenuItem<String>(
                  value: adherent.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        adherent.nomComplet,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${adherent.montantContributionFormate}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  if (_selectedAdherentId != value) {
                    _selectedAdherentId = value;
                    _selectedCotisationId = null;
                  }
                });
              },
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCotisationCard() {
    final adherentCotisations = _cotisations
        .where((c) => c.adherentId == _selectedAdherent!.id)
        .toList()
      ..sort((a, b) => b.annee.compareTo(a.annee));

    if (adherentCotisations.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Aucune cotisation',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cet adherent n\'a pas encore de cotisation',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.add),
              label: Text('Creer une cotisation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '2. Choisissez une cotisation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          ...adherentCotisations.map((cotisation) {
            final estSoldee = cotisation.estSoldee;
            final isSelected = _selectedCotisationId == cotisation.id;
            return Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: estSoldee ? null : () {
                    setState(() {
                      _selectedCotisationId = cotisation.id;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: estSoldee
                          ? Colors.grey[50]
                          : isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 32,
                          decoration: BoxDecoration(
                            color: estSoldee
                                ? Colors.green
                                : cotisation.montantPaye > 0
                                ? Colors.orange
                                : Colors.red,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Annee ${cotisation.annee}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    cotisation.montantFormate,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Spacer(),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: estSoldee
                                          ? Colors.green
                                          : cotisation.montantPaye > 0
                                          ? Colors.orange
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      cotisation.statut,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Paye: ${cotisation.montantPayeFormate}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    ' / ${cotisation.montantFormate}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    '${cotisation.pourcentagePaye.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!estSoldee)
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[400],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '3. Resume du paiement',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow('Adherent', _selectedAdherent!.nomComplet),
                _buildSummaryRow('Annee', '${_selectedCotisation!.annee}'),
                _buildSummaryRow('Contribution', _selectedCotisation!.montantFormate),
                _buildSummaryRow('Deja paye', _selectedCotisation!.montantPayeFormate),
                Divider(height: 16),
                _buildSummaryRow(
                  'Reste a payer',
                  _selectedCotisation!.resteFormate,
                  valueColor: Colors.red,
                  valueBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor, bool valueBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _showPaymentDialog,
        icon: Icon(Icons.payment),
        label: Text(
          'Effectuer un paiement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(
        cotisation: _selectedCotisation!,
        adherent: _selectedAdherent!,
      ),
    ).then((_) {
      _loadData();
    });
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
  String _methodePaiement = 'Espece';
  DateTime _datePaiement = DateTime.now();

  @override
  void initState() {
    super.initState();
    _montantController.text = widget.cotisation.resteAPayer.toString();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.payment,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nouveau Paiement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.adherent.nomComplet} • Annee ${widget.cotisation.annee}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Resume
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('Contribution', widget.cotisation.montantFormate),
                      _buildSummaryRow('Deja paye', widget.cotisation.montantPayeFormate),
                      Divider(),
                      _buildSummaryRow(
                        'Reste a payer',
                        widget.cotisation.resteFormate,
                        valueColor: Colors.red,
                        valueBold: true,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Date de paiement
                Text(
                  'Date du paiement',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        SizedBox(width: 12),
                        Text(
                          DateFormat('dd MMM yyyy').format(_datePaiement),
                          style: TextStyle(fontSize: 16),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Methode de paiement
                DropdownButtonFormField<String>(
                  value: _methodePaiement,
                  decoration: InputDecoration(
                    labelText: 'Methode de paiement',
                    prefixIcon: Icon(Icons.payment),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: [
                    DropdownMenuItem(value: 'Espece', child: Text('Espece')),
                    DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
                    DropdownMenuItem(value: 'Virement', child: Text('Virement')),
                    DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _methodePaiement = value!;
                    });
                  },
                ),

                SizedBox(height: 16),

                // Montant
                TextFormField(
                  controller: _montantController,
                  decoration: InputDecoration(
                    labelText: 'Montant a payer (FCFA)',
                    prefixIcon: Icon(Icons.money),
                    hintText: 'Maximum: ${widget.cotisation.resteFormate}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Champ obligatoire';
                    final montant = int.tryParse(value!);
                    if (montant == null) return 'Montant invalide';
                    if (montant <= 0) return 'Le montant doit etre positif';
                    if (montant > widget.cotisation.resteAPayer) {
                      return 'Le montant ne peut pas depasser le reste a payer';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (optionnel)',
                    prefixIcon: Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                ),

                SizedBox(height: 24),

                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Annuler'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _processPayment,
                        child: Text('Confirmer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor, bool valueBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _datePaiement,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );
    if (picked != null && picked != _datePaiement) {
      setState(() {
        _datePaiement = picked;
      });
    }
  }

  void _processPayment() {
    if (_formKey.currentState?.validate() == true) {
      final montant = int.parse(_montantController.text);
      final nouveauMontantPaye = widget.cotisation.montantPaye + montant;

      // Créer et sauvegarder le paiement dans Firebase
      final paiement = Paiement(
        adherentId: widget.adherent.id,
        annee: widget.cotisation.annee,
        montantVerse: montant,
        datePaiement: _datePaiement,
        statut: StatutPaiement.complete,
        methode: _convertMethodePaiement(_methodePaiement),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      // Sauvegarder le paiement
      ref.read(paiementProvider.notifier).addPaiement(paiement);

      // Mettre à jour la cotisation
      final cotisationMaj = widget.cotisation.copyWith(
        montantPaye: nouveauMontantPaye,
        dateModification: DateTime.now(),
        motifModification: 'Paiement de $montant FCFA par $_methodePaiement${_notesController.text.isNotEmpty ? ' - ${_notesController.text}' : ''}',
      );

      ref.read(cotisationProvider.notifier).updateCotisation(cotisationMaj);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement de $montant FCFA enregistre avec succes!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  MethodePaiement _convertMethodePaiement(String methode) {
    switch (methode) {
      case 'Espece':
        return MethodePaiement.espece;
      case 'Mobile Money':
        return MethodePaiement.mobileMoney;
      case 'Virement':
        return MethodePaiement.virement;
      case 'Cheque':
        return MethodePaiement.cheque;
      default:
        return MethodePaiement.espece;
    }
  }
}