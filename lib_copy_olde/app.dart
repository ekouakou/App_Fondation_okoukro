import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'widgets/main_screen_wrapper.dart';

/// Widget principal de l'application
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScreenWrapper(child: HomeScreen());
  }
}

/// Écran placeholder pour les notes (nécessite de sélectionner un enfant)
class NotesPlaceholderScreen extends StatelessWidget {
  const NotesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grade,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez un enfant depuis l\'écran d\'accueil',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


