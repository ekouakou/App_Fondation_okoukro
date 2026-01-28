import 'package:flutter/material.dart';
import '../widgets/main_screen_wrapper.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../widgets/custom_card.dart';
import '../config/app_colors.dart';

/// Écran de messagerie - Affiche uniquement les notifications FCM reçues
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final parentId = MainScreenWrapper.of(context).currentUserId ?? 'parent1';
      
      // Charger uniquement les notifications FCM depuis la base de données
      final databaseService = DatabaseService.instance;
      final notifications = await databaseService.getNotificationsByParent(parentId);
      
      setState(() {
        _notifications = notifications;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Trier les notifications par date (plus récent en premier)
    _notifications.sort((a, b) {
      final dateA = DateTime.fromMillisecondsSinceEpoch(a['timestamp'] as int);
      final dateB = DateTime.fromMillisecondsSinceEpoch(b['timestamp'] as int);
      return dateB.compareTo(dateA);
    });

    if (_notifications.isEmpty) {
      return Center(
        child: Text(
          'Aucune notification',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(_notifications[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(notification['timestamp'] as int);
    final isRead = notification['isRead'] as bool? ?? false;
    final sender = notification['sender'] as String? ?? 'Direction de l\'établissement';
    final data = notification['data'] as Map<String, dynamic>?;
    
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _showNotificationDetail(notification),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (!isRead)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                sender,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showNotificationDetail(notification),
              child: const Text('Voir plus'),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetail(Map<String, dynamic> notification) async {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(notification['timestamp'] as int);
    final sender = notification['sender'] as String? ?? 'Direction de l\'établissement';
    final data = notification['data'] as Map<String, dynamic>?;
    final notificationId = notification['id'] as String;
    final isRead = notification['isRead'] as bool? ?? false;
    
    // Marquer comme lu si ce n'est pas déjà fait
    if (!isRead) {
      try {
        final databaseService = DatabaseService.instance;
        await databaseService.markNotificationAsRead(notificationId);
        // Mettre à jour l'état local
        setState(() {
          notification['isRead'] = true;
        });
      } catch (e) {
        print('❌ Erreur lors du marquage de la notification comme lue: $e');
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'De: $sender',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                'Date: ${_formatDate(timestamp)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              Text(body),
              if (data != null && data.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Détails:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...data.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

