import 'package:flutter/material.dart';
import '../models/fee.dart';
import '../services/api_service.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_card.dart';

/// Écran d'affichage des frais de scolarité
class FeesScreen extends StatefulWidget {
  final String childId;

  const FeesScreen({
    super.key,
    required this.childId,
  });

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  List<Fee> _fees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = MainScreenWrapper.of(context).apiService;
      final fees = await apiService.getFeesForChild(widget.childId);
      
      setState(() {
        _fees = fees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fees.isEmpty) {
      return Center(
        child: Text(
          'Aucun frais enregistré',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final paidFees = _fees.where((f) => f.isPaid).toList();
    final unpaidFees = _fees.where((f) => !f.isPaid).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (unpaidFees.isNotEmpty) ...[
            Text(
              'Frais à régler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 8),
            ...unpaidFees.map((fee) => _buildFeeCard(fee)),
            const SizedBox(height: 24),
          ],
          if (paidFees.isNotEmpty) ...[
            Text(
              'Frais payés',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
            const SizedBox(height: 8),
            ...paidFees.map((fee) => _buildFeeCard(fee)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeCard(Fee fee) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: fee.isPaid ? Colors.green[50] : Colors.red[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fee.type,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: fee.isPaid ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  fee.isPaid ? 'Payé' : 'Non payé',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Montant: ${fee.amount.toStringAsFixed(0)} FCFA',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Date d\'échéance: ${_formatDate(fee.dueDate)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (fee.isPaid && fee.paidDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Payé le: ${_formatDate(fee.paidDate!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green[700],
                  ),
            ),
            if (fee.paymentMethod != null) ...[
              const SizedBox(height: 4),
              Text(
                'Méthode: ${fee.paymentMethod}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (fee.reference != null) ...[
              const SizedBox(height: 4),
              Text(
                'Référence: ${fee.reference}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

