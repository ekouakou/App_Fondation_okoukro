import 'pouls_scolaire_api_service.dart';
import '../models/ecole.dart';
import '../models/eleve.dart';
import '../models/matiere.dart';

/// Exemple d'utilisation du service Pouls Scolaire API
/// 
/// Ce fichier montre comment utiliser le service pour charger les données
/// depuis l'API Pouls Scolaire.
class PoulsScolaireExample {
  final PoulsScolaireApiService _apiService = PoulsScolaireApiService();

  /// Exemple 1: Charger toutes les écoles
  Future<void> loadAllEcoles() async {
    try {
      final ecoles = await _apiService.getAllEcoles();
      print('Nombre d\'écoles: ${ecoles.length}');
      for (final ecole in ecoles) {
        print('${ecole.ecolecode}: ${ecole.ecoleclibelle}');
      }
    } catch (e) {
      print('Erreur: $e');
    }
  }

  /// Exemple 2: Charger toutes les données pour une école
  /// (année, classes, périodes, élèves)
  Future<void> loadAllDataForEcole(int ecoleId) async {
    try {
      final schoolData = await _apiService.loadAllDataForEcole(ecoleId);
      
      print('École ID: ${schoolData.ecoleId}');
      print('Année scolaire: ${schoolData.anneeScolaire.anneeEcoleList.first.anneeLibelle}');
      print('Nombre de classes: ${schoolData.classes.length}');
      print('Nombre de périodes: ${schoolData.periodes.length}');
      print('Nombre total d\'élèves: ${schoolData.eleves.length}');
      
      // Afficher les élèves par classe
      for (final classe in schoolData.classes) {
        final eleves = schoolData.getElevesByClasse(classe.id);
        print('Classe ${classe.libelle}: ${eleves.length} élèves');
      }
    } catch (e) {
      print('Erreur: $e');
    }
  }

  /// Exemple 3: Charger les données étape par étape
  Future<void> loadDataStepByStep(int ecoleId) async {
    try {
      // 1. Charger l'année scolaire
      final anneeScolaire = await _apiService.getAnneeScolaireOuverte(ecoleId);
      print('Année ouverte: ${anneeScolaire.anneeEcoleList.first.anneeLibelle}');
      
      // 2. Charger les classes
      final classes = await _apiService.getClassesByEcole(ecoleId);
      print('Classes: ${classes.length}');
      
      // 3. Charger les périodes
      final periodes = await _apiService.getAllPeriodes();
      print('Périodes: ${periodes.length}');
      
      // 4. Charger les élèves
      final idAnnee = anneeScolaire.anneeOuverteCentraleId;
      final eleves = await _apiService.getElevesByEcoleAndAnnee(ecoleId, idAnnee);
      print('Élèves: ${eleves.length}');
      
      // 5. Grouper les élèves par classe
      final Map<int, List<Eleve>> elevesParClasse = {};
      for (final eleve in eleves) {
        if (!elevesParClasse.containsKey(eleve.classeid)) {
          elevesParClasse[eleve.classeid] = [];
        }
        elevesParClasse[eleve.classeid]!.add(eleve);
      }
      
      // Afficher le résultat
      for (final classe in classes) {
        final elevesClasse = elevesParClasse[classe.id] ?? [];
        print('${classe.libelle}: ${elevesClasse.length} élèves');
      }
    } catch (e) {
      print('Erreur: $e');
    }
  }

  /// Exemple 4: Charger les matières d'une école et d'une classe
  Future<void> loadMatieres(int idEcole, int classeId) async {
    try {
      final matieres = await _apiService.getMatieresByEcoleAndClasse(idEcole, classeId);
      print('Nombre de matières: ${matieres.length}');
      for (final matiere in matieres) {
        print('${matiere.id}: ${matiere.libelle}');
      }
    } catch (e) {
      print('Erreur: $e');
    }
  }
}

