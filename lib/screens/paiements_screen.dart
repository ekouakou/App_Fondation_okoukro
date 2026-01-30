import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/adherent_provider.dart';
import '../providers/cotisation_provider.dart';
import '../providers/paiement_provider.dart';
import '../models/adherent.dart';
import '../models/cotisation.dart';
import '../models/paiement.dart';
import '../config/app_colors.dart';
import '../widgets/searchable_adherent_dropdown.dart';

class PaiementsWizardScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<PaiementsWizardScreen> createState() => _PaiementsWizardScreenState();
}

class _PaiementsWizardScreenState extends ConsumerState<PaiementsWizardScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  Adherent? _selectedAdherent;
  String? _selectedCotisationId;
  List<Adherent> _adherents = [];
  List<Cotisation> _cotisations = [];
  
  // Controllers pour l'étape de paiement
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _notesController = TextEditingController();
  String _methodePaiement = 'Espece';
  DateTime _datePaiement = DateTime.now();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Cotisation? get _selectedCotisation =>
      _selectedCotisationId == null ? null : _cotisations.firstWhere(
            (c) => c.id == _selectedCotisationId,
        orElse: () => _cotisations.first,
      );

  @override
  void initState() {
    super.initState();
    _loadData();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  // Ajouter une méthode pour forcer le rafraîchissement complet quand l'écran redevient actif
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger les données chaque fois que l'écran redevient visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _montantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Forcer le rechargement complet depuis Firestore pour éviter les données en cache
    await ref.read(adherentProvider.notifier).loadAdherents();
    await ref.read(cotisationProvider.notifier).loadCotisations();
    await ref.read(paiementProvider.notifier).loadPaiements();

    final adherentsAsync = ref.read(adherentProvider);
    final cotisationsAsync = ref.read(cotisationProvider);

    if (adherentsAsync.hasValue && cotisationsAsync.hasValue) {
      setState(() {
        final uniqueAdherents = <String, Adherent>{};
        for (final adherent in adherentsAsync.value!) {
          if (adherent.id.isNotEmpty) {
            uniqueAdherents[adherent.id] = adherent;
          }
        }
        _adherents = uniqueAdherents.values.toList();
        _adherents.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
        _cotisations = cotisationsAsync.value!;

        if (_selectedAdherent != null && !_adherents.any((a) => a.id == _selectedAdherent!.id)) {
          _selectedAdherent = null;
          _selectedCotisationId = null;
        }
        if (_selectedCotisationId != null && !_cotisations.any((c) => c.id == _selectedCotisationId)) {
          _selectedCotisationId = null;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _animationController.reset();
      setState(() {
        _currentStep++;
      });
      _animationController.forward();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reset();
      setState(() {
        _currentStep--;
      });
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.all(12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payment_rounded,
              color: AppColors.white,
              size: 20,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Processus guidé en 3 étapes',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStepDot(0, 'Adhérent'),
          Expanded(child: _buildStepLine(0)),
          _buildStepDot(1, 'Cotisation'),
          Expanded(child: _buildStepLine(1)),
          _buildStepDot(2, 'Paiement'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive 
                ? AppColors.primary 
                : isCompleted 
                    ? AppColors.success 
                    : AppColors.grey300,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.grey300,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.grey600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.primary : AppColors.grey600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = step < _currentStep;
    return Container(
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success : AppColors.grey300,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildAdherentStep();
      case 1:
        return _buildCotisationStep();
      case 2:
        return _buildPaymentStep();
      default:
        return Container();
    }
  }

  Widget _buildAdherentStep() {
    return _buildAdherentCard();
  }

  Widget _buildCotisationStep() {
    final adherentCotisations = _cotisations
        .where((c) => c.adherentId == _selectedAdherent!.id)
        .toList()
      ..sort((a, b) => b.annee.compareTo(a.annee));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choisissez une cotisation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryLight,
          ),
        ),
        SizedBox(height: 12),
        if (adherentCotisations.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 32),
                SizedBox(height: 8),
                Text(
                  'Aucune cotisation',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          )
        else
          ...adherentCotisations.map((cotisation) {
              final isSelected = _selectedCotisationId == cotisation.id;
              final estSoldee = cotisation.estSoldee;
              final estPartiel = cotisation.montantPaye > 0 && cotisation.montantPaye < cotisation.montantAnnuel;
              final canSelect = !estSoldee; // On ne peut sélectionner que les cotisations non soldées
              
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: canSelect ? () {
                      setState(() {
                        _selectedCotisationId = cotisation.id;
                      });
                    } : null, // Désactivé si soldée
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected && canSelect ? AppColors.primary : AppColors.borderLight,
                          width: isSelected && canSelect ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: estSoldee 
                          ? Colors.grey.shade100 // Grisé si soldée
                          : isSelected 
                            ? AppColors.primarySurface 
                            : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Année ${cotisation.annee}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            color: estSoldee 
                                              ? Colors.grey.shade500 
                                              : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        if (estSoldee)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade400,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Soldée',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        if (estPartiel)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.warning,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Partiel',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Montant total',
                                              style: TextStyle(
                                                color: estSoldee 
                                                  ? Colors.grey.shade400 
                                                  : AppColors.textSecondaryLight,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              cotisation.montantFormate,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: estSoldee 
                                                  ? Colors.grey.shade500 
                                                  : AppColors.textPrimaryLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 24),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Déjà payé',
                                              style: TextStyle(
                                                color: estSoldee 
                                                  ? Colors.grey.shade400 
                                                  : AppColors.textSecondaryLight,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              cotisation.montantPayeFormate,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: estSoldee 
                                                  ? Colors.grey.shade500 
                                                  : AppColors.success,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (!estSoldee) ...[
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning_amber, color: AppColors.error, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              'Reste à payer: ${cotisation.resteFormate}',
                                              style: TextStyle(
                                                color: AppColors.error,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (estSoldee) ...[
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.grey.shade600, size: 16),
                                            SizedBox(width: 6),
                                            Text(
                                              'Cotisation entièrement payée',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                estSoldee 
                                  ? Icons.check_circle 
                                  : isSelected 
                                    ? Icons.check_circle 
                                    : Icons.circle_outlined,
                                color: estSoldee 
                                  ? Colors.grey.shade400 
                                  : isSelected 
                                    ? AppColors.primary 
                                    : AppColors.grey400,
                                size: 24,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif du paiement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Adhérent', _selectedAdherent!.nomComplet),
                _buildSummaryRow('Année', '${_selectedCotisation!.annee}'),
                _buildSummaryRow('Montant total', _selectedCotisation!.montantFormate),
                _buildSummaryRow('Déjà payé', _selectedCotisation!.montantPayeFormate),
                Divider(height: 16),
                _buildSummaryRow(
                  'Reste à payer',
                  _selectedCotisation!.resteFormate,
                  valueColor: AppColors.error,
                  valueBold: true,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Détails du paiement',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          SizedBox(height: 8),
          TextFormField(
            controller: _montantController,
            decoration: InputDecoration(
              labelText: 'Montant à payer',
              hintText: 'Maximum: ${_selectedCotisation!.resteFormate}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un montant';
              }
              final montant = int.tryParse(value);
              if (montant == null || montant <= 0) {
                return 'Le montant doit être positif';
              }
              if (montant > _selectedCotisation!.resteAPayer) {
                return 'Le montant ne peut pas dépasser ${_selectedCotisation!.resteFormate}';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (optionnel)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildAdherentCard() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.people_rounded, color: AppColors.primary, size: 16),
              ),
              SizedBox(width: 8),
              Text(
                'Choisissez un adhérent',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SearchableAdherentDropdown(
            label: 'Rechercher un adhérent',
            selectedAdherent: _selectedAdherent,
            adherents: _adherents,
            isRequired: true,
            onChanged: (Adherent? value) {
              setState(() {
                if (_selectedAdherent?.id != value?.id) {
                  _selectedAdherent = value;
                  _selectedCotisationId = null;
                }
              });
            },
          ),
        ],
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
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimaryLight,
              fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
              fontSize: valueBold ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: _previousStep,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16),
                    SizedBox(width: 4),
                    Text('Précédent'),
                  ],
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
          SizedBox(
            width: 100,
            child: ElevatedButton(
              onPressed: _currentStep < 2 && _canProceed() ? _nextStep : _processPaymentWrapper,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_currentStep < 2 ? 'Suivant' : 'Confirmer'),
                  if (_currentStep < 2) ...[
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ] else ...[
                    SizedBox(width: 4),
                    Icon(Icons.check, size: 16),
                  ],
                ],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < 2 ? AppColors.primary : AppColors.success,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedAdherent != null;
      case 1:
        return _selectedCotisation != null;
      case 2:
        return _montantController.text.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _processPayment() async {
    if (_formKey.currentState?.validate() == true) {
      final montant = int.tryParse(_montantController.text) ?? 0;
      
      if (montant <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Le montant doit être positif'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (montant > _selectedCotisation!.resteAPayer) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Le montant ne peut pas dépasser le reste à payer'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final paiement = Paiement(
        adherentId: _selectedAdherent!.id,
        annee: _selectedCotisation!.annee,
        montantVerse: montant,
        datePaiement: DateTime.now(),
        statut: StatutPaiement.complete,
        methode: MethodePaiement.espece,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      ref.read(paiementProvider.notifier).addPaiement(paiement);

      final cotisationMaj = _selectedCotisation!.copyWith(
        montantPaye: _selectedCotisation!.montantPaye + montant,
        dateModification: DateTime.now(),
        motifModification: 'Paiement de $montant FCFA',
      );

      ref.read(cotisationProvider.notifier).updateCotisation(cotisationMaj);

      // Recharger les données pour mettre à jour l'interface
      await _loadData();

      // Forcer un court délai pour s'assurer que tous les caches sont bien rafraîchis
      await Future.delayed(Duration(milliseconds: 500));
      
      // Recharger une deuxième fois pour être certain que tout est synchronisé
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Paiement de $montant FCFA enregistré avec succès!'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reset the form after successful payment
      setState(() {
        _currentStep = 0;
        _selectedAdherent = null;
        _selectedCotisationId = null;
        _montantController.clear();
        _notesController.clear();
      });
    }
  }

  void _processPaymentWrapper() {
    _processPayment();
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