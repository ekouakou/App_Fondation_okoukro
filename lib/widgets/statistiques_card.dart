import 'package:flutter/material.dart';

class StatistiquesCard extends StatelessWidget {
  final String titre;
  final String valeur;
  final IconData icone;
  final Color couleur;

  const StatistiquesCard({
    Key? key,
    required this.titre,
    required this.valeur,
    required this.icone,
    required this.couleur,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: couleur.withOpacity(0.1),
                  child: Icon(
                    icone,
                    color: couleur,
                    size: 24,
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: Colors.grey,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              titre,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              valeur,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: couleur,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
