import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/adherent.dart';

/// Widget Dropdown avec recherche intégrée pour les adhérents
class SearchableAdherentDropdown extends StatefulWidget {
  final String label;
  final Adherent? selectedAdherent;
  final List<Adherent> adherents;
  final Function(Adherent?) onChanged;
  final bool isRequired;
  final String? Function(Adherent?)? validator;

  const SearchableAdherentDropdown({
    super.key,
    required this.label,
    this.selectedAdherent,
    required this.adherents,
    required this.onChanged,
    this.isRequired = false,
    this.validator,
  });

  @override
  State<SearchableAdherentDropdown> createState() => _SearchableAdherentDropdownState();
}

class _SearchableAdherentDropdownState extends State<SearchableAdherentDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Adherent> _filteredAdherents = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _filteredAdherents = widget.adherents;
  }

  @override
  void didUpdateWidget(SearchableAdherentDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mettre à jour la liste filtrée quand la liste des adhérents change
    if (oldWidget.adherents != widget.adherents) {
      setState(() {
        _filteredAdherents = widget.adherents;
        // Si le champ de recherche n'est pas vide, appliquer le filtre
        if (_searchController.text.isNotEmpty) {
          _filterAdherents(_searchController.text);
        }
      });
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
      _isFocused = true;
    });
    
    // Focus sur le champ de recherche
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchFocusNode.requestFocus();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_searchController.hasListeners) {
      _searchController.clear();
    }
    _filteredAdherents = widget.adherents;
    setState(() {
      _isOpen = false;
      _isFocused = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        child: Stack(
          children: [
            // Zone transparente pour capturer les clics extérieurs
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
            // Dropdown content
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height + 5.0),
                child: GestureDetector(
                  onTap: () {}, // Empêcher la propagation du clic
                  child: Material(
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Champ de recherche
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: 'Rechercher un adhérent...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey.shade600,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                              onChanged: _filterAdherents,
                            ),
                          ),
                          // Liste des adhérents
                          Flexible(
                            child: _filteredAdherents.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'Aucun adhérent trouvé',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: _filteredAdherents.length,
                                    itemBuilder: (context, index) {
                                      final adherent = _filteredAdherents[index];
                                      final isSelected = adherent.id == widget.selectedAdherent?.id;
                                      
                                      return InkWell(
                                        onTap: () {
                                          widget.onChanged(adherent);
                                          _removeOverlay();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary.withOpacity(0.1)
                                                : null,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey.shade200.withOpacity(0.5),
                                                width: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      adherent.nomComplet,
                                                      style: TextStyle(
                                                        color: isSelected
                                                            ? AppColors.primary
                                                            : Colors.black87,
                                                        fontSize: 12,
                                                        fontWeight: isSelected 
                                                            ? FontWeight.w600 
                                                            : FontWeight.w500,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      adherent.telephone,
                                                      style: TextStyle(
                                                        color: Colors.grey.shade600,
                                                        fontSize: 10,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Icon(
                                                  Icons.check,
                                                  color: AppColors.primary,
                                                  size: 16,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterAdherents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAdherents = widget.adherents;
      } else {
        _filteredAdherents = widget.adherents
            .where((adherent) => 
                adherent.nom.toLowerCase().contains(query.toLowerCase()) ||
                adherent.prenom.toLowerCase().contains(query.toLowerCase()) ||
                adherent.telephone.contains(query))
            .toList();
      }
    });
    
    // Mettre à jour l'overlay
    _overlayEntry?.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.validator != null && widget.selectedAdherent == null && widget.isRequired;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          '${widget.label}${widget.isRequired ? ' *' : ''}',
          style: TextStyle(
            color: hasError ? Colors.red : (_isFocused ? AppColors.primary : Colors.grey.shade600),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        // Dropdown
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError 
                      ? Colors.red
                      : _isFocused
                          ? AppColors.primary
                          : Colors.grey.shade300,
                  width: _isFocused ? 2 : 1,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isFocused 
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 18,
                      color: _isFocused 
                          ? AppColors.primary 
                          : Colors.grey.shade600,
                    ),
                  ),
                  Expanded(
                    child: widget.selectedAdherent != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.selectedAdherent!.nomComplet,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                widget.selectedAdherent!.telephone,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : Text(
                            'Sélectionner un adhérent',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Message d'erreur
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.validator!(null) ?? 'Champ obligatoire',
              style: TextStyle(
                color: Colors.red,
                fontSize: 10,
              ),
            ),
          ),
      ],
    );
  }
}
