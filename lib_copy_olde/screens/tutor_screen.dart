import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../widgets/main_screen_wrapper.dart';
import '../widgets/custom_search_bar.dart';
import '../utils/image_helper.dart';

/// Écran des services de tutorat
class TutorScreen extends StatefulWidget implements MainScreenChild {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  String _selectedFilter = 'Tous';
  bool _isSearching = false;
  TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['Tous', 'Soutien', 'Conseil', 'Formation', 'En ligne'];
//                       'Soutien Scolaire\nPour Un Meilleur Résultat',

  final List<Map<String, String>> _tutorItems = [
    {
      'title': 'Mathématiques',
      'subtitle': 'Soutien scolaire primaire et collège',
      'type': 'Soutien',
      'icon': 'calculate',
      'color': '0xFF3B82F6',
      'image': 'https://picsum.photos/seed/math/400/300.jpg',
    },
    {
      'title': 'Français',
      'subtitle': 'Grammaire et rédaction',
      'type': 'Soutien',
      'icon': 'menu_book',
      'color': '0xFF8B5CF6',
      'image': 'https://picsum.photos/seed/french/400/300.jpg',
    },
    {
      'title': 'Physique-Chimie',
      'subtitle': 'Expériences et théorie',
      'type': 'Soutien',
      'icon': 'science',
      'color': '0xFF10B981',
      'image': 'https://picsum.photos/seed/physics/400/300.jpg',
    },
    {
      'title': 'Conseil Parental',
      'subtitle': 'Accompagnement éducatif',
      'type': 'Conseil',
      'icon': 'psychology',
      'color': '0xFFF59E0B',
      'image': 'https://picsum.photos/seed/parenting/400/300.jpg',
    },
    {
      'title': 'Formation Enseignants',
      'subtitle': 'Pédagogie moderne',
      'type': 'Formation',
      'icon': 'school',
      'color': '0xFF6366F1',
      'image': 'https://picsum.photos/seed/teaching/400/300.jpg',
    },
    {
      'title': 'Tutorat En Ligne',
      'subtitle': 'Cours visioconférence',
      'type': 'En ligne',
      'icon': 'videocam',
      'color': '0xFFEF4444',
      'image': 'https://picsum.photos/seed/online/400/300.jpg',
    },
    {
      'title': 'Anglais',
      'subtitle': 'Apprentissage linguistique',
      'type': 'Soutien',
      'icon': 'language',
      'color': '0xFF10B981',
      'image': 'https://picsum.photos/seed/english/400/300.jpg',
    },
    {
      'title': 'Méthodologie',
      'subtitle': 'Organisation et apprentissage',
      'type': 'Conseil',
      'icon': 'lightbulb',
      'color': '0xFFF59E0B',
      'image': 'https://picsum.photos/seed/methodology/400/300.jpg',
    },
  ];

  List<Map<String, String>> get _filteredItems {
    var items = _tutorItems;
    
    // Apply filter
    if (_selectedFilter != 'Tous') {
      items = items.where((item) => item['type'] == _selectedFilter).toList();
    }
    
    // Apply search
    if (_searchController.text.isNotEmpty) {
      final searchQuery = _searchController.text.toLowerCase();
      items = items.where((item) => 
        item['title']!.toLowerCase().contains(searchQuery) ||
        item['subtitle']!.toLowerCase().contains(searchQuery)
      ).toList();
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.getPureBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getPureAppBarBackground(isDark),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Services de Tutorat',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar with Slide Down Animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isSearching ? 56 : 0,
            margin: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: _isSearching ? 8 : 0,
            ),
            child: _isSearching
                ? CustomSearchBar(
                    hintText: 'Rechercher un service...',
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                    },
                    onClear: () {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                      });
                    },
                    autoFocus: true,
                  )
                : null,
          ),
          
          // Filter Tabs
          Container(
            height: 35,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: !isSelected ? AppColors.getSurfaceColor(isDark) : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : [],
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected 
                          ? Colors.white 
                          : AppColors.getTextColor(isDark),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Results Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Text(
                  '${_filteredItems.length} services',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Grid View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return _buildTutorCard(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorCard(Map<String, String> item) {
    final Color color = Color(int.parse(item['color']!));
    final String? imageUrl = item['image'];
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: ImageHelper.buildNetworkImage(
                imageUrl: imageUrl,
                placeholder: item['title'] ?? 'Image',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item['title']!,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Subtitle
                  Text(
                    item['subtitle']!,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item['type']!,
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

