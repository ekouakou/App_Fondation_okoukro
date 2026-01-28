import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ecole.dart';
import '../models/classe.dart';
import '../models/annee_scolaire.dart';
import '../models/eleve.dart';
import '../models/periode.dart';
import '../models/matiere.dart';
import '../models/note_api.dart';
import '../models/note_classe_dto.dart';

/// Classe pour retourner les notes avec les informations globales
class NotesResult {
  final List<NoteApi> notes;
  final double? moyenneGlobale;
  final int? rangGlobal;

  NotesResult({
    required this.notes,
    this.moyenneGlobale,
    this.rangGlobal,
  });
}

/// Service pour interagir avec l'API Pouls Scolaire
class PoulsScolaireApiService {
  // Utiliser l'URL depuis AppConfig pour faciliter la configuration
  String get _baseUrl => AppConfig.POULS_SCOLAIRE_API_URL;

  /// Headers requis pour toutes les requêtes
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Récupère toutes les écoles disponibles
  /// 
  /// Endpoint: GET /connecte/ecole
  Future<List<Ecole>> getAllEcoles() async {
    try {
      final uri = Uri.parse('$_baseUrl/connecte/ecole');
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('🏫 CHARGEMENT DES ÉCOLES');
      print('═══════════════════════════════════════════════════════════');
      print('🔗 URL: $uri');
      print('📡 Envoi de la requête...');
      
      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');
      print('   - Body length: ${response.body.length} caractères');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          print('✅ ${data.length} école(s) trouvée(s)');
          
          if (data.isEmpty) {
            print('⚠️ La liste des écoles est vide');
          } else {
            print('📋 Premières écoles:');
            for (int i = 0; i < (data.length > 3 ? 3 : data.length); i++) {
              final ecoleJson = data[i] as Map<String, dynamic>;
              print('   ${i + 1}. ${ecoleJson['ecoleclibelle'] ?? 'N/A'} (ID: ${ecoleJson['ecoleid'] ?? 'N/A'})');
            }
          }
          
          final ecoles = data.map((json) => Ecole.fromJson(json as Map<String, dynamic>)).toList();
          print('═══════════════════════════════════════════════════════════');
          print('✅ FIN CHARGEMENT DES ÉCOLES');
          print('═══════════════════════════════════════════════════════════');
          print('');
          return ecoles;
        } catch (e) {
          print('❌ Erreur lors du parsing JSON: $e');
          print('❌ Contenu de la réponse (premiers 500 caractères):');
          print('   ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          print('═══════════════════════════════════════════════════════════');
          print('');
          throw Exception('Erreur lors du parsing des écoles: $e');
        }
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception(
          'Erreur lors de la récupération des écoles: ${response.statusCode}. ${response.body}',
        );
      }
    } catch (e) {
      print('');
      print('❌ Exception lors de la récupération des écoles: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      
      // Gérer les différents types d'erreurs
      if (e is http.ClientException) {
        final errorMsg = e.message.toLowerCase();
        if (errorMsg.contains('failed host lookup') || errorMsg.contains('no address associated')) {
          throw Exception(
            'Impossible de résoudre le nom de domaine "api-pro.pouls-scolaire.net".\n\n'
            'Vérifications à faire :\n'
            '1. Vérifiez votre connexion internet\n'
            '2. Testez l\'URL dans un navigateur : https://api-pro.pouls-scolaire.net/api/connecte/ecole\n'
            '3. Si vous êtes sur un émulateur Android, vérifiez que l\'émulateur a accès à internet\n'
            '4. Vérifiez que le nom de domaine est correct\n'
            '5. Vérifiez les paramètres DNS de votre réseau'
          );
        }
        throw Exception('Erreur de connexion: ${e.message}. Vérifiez votre connexion internet.');
      } else if (e is TimeoutException) {
        throw Exception('La requête a pris trop de temps. Veuillez réessayer.');
      } else {
        throw Exception('Erreur lors de la récupération des écoles: $e');
      }
    }
  }

  /// Récupère les classes d'une école
  /// 
  /// Endpoint: GET /classes/list-all-populate-by-ecole?ecole={ecoleId}
  Future<List<Classe>> getClassesByEcole(int ecoleId) async {
    try {
      final uri = Uri.parse('$_baseUrl/classes/list-all-populate-by-ecole')
          .replace(queryParameters: {'ecole': ecoleId.toString()});
      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Classe.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des classes: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des classes: $e');
    }
  }

  /// Récupère l'année scolaire ouverte pour une école
  /// 
  /// Endpoint: GET /annee/list-ouverte-to-ecole-dto?ecole={ecoleId}
  Future<AnneeScolaire> getAnneeScolaireOuverte(int ecoleId) async {
    try {
      final uri = Uri.parse('$_baseUrl/annee/list-ouverte-to-ecole-dto')
          .replace(queryParameters: {'ecole': ecoleId.toString()});
      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          return AnneeScolaire.fromJson(data);
        } catch (e) {
          // Log la réponse pour le débogage
          print('Erreur de parsing JSON: $e');
          print('Réponse API: ${response.body}');
          throw Exception(
            'Erreur lors du parsing de la réponse de l\'API: $e',
          );
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération de l\'année scolaire: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur lors de la récupération de l\'année scolaire: $e');
    }
  }

  /// Récupère les élèves d'une école et d'une année
  /// 
  /// Endpoint: GET /inscriptions/list-eleve-classe/{idEcole}/{idAnnee}
  Future<List<Eleve>> getElevesByEcoleAndAnnee(int idEcole, int idAnnee) async {
    try {
      final uri = Uri.parse('$_baseUrl/inscriptions/list-eleve-classe/$idEcole/$idAnnee');
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('📚 CHARGEMENT DES ÉLÈVES');
      print('═══════════════════════════════════════════════════════════');
      print('🔗 URL complète de la ressource API:');
      print('   $uri');
      print('');
      print('📅 Identifiant de l\'année utilisé: $idAnnee');
      print('🏫 Identifiant de l\'école utilisé: $idEcole');
      print('═══════════════════════════════════════════════════════════');
      print('');
      
      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Réponse reçue: ${data.length} élèves récupérés');
        print('');
        
        // Chercher spécifiquement le matricule 25125794Q
        bool foundTargetMatricule = false;
        for (final eleveData in data) {
          final eleveJson = eleveData as Map<String, dynamic>;
          final matricule = eleveJson['matriculeEleve']?.toString() ?? '';
          if (matricule == '25125794Q' || matricule.toUpperCase() == '25125794Q') {
            foundTargetMatricule = true;
            print('🎯 ÉLÈVE TROUVÉ - Matricule: 25125794Q');
            print('   📋 Tous les champs retournés par l\'API:');
            eleveJson.forEach((key, value) {
              print('      - $key: $value');
            });
            print('   🔍 Vérification des champs de classe:');
            print('      - classeid: ${eleveJson['classeid']}');
            print('      - classe: ${eleveJson['classe']}');
            print('      - brancheid: ${eleveJson['brancheid']}');
            print('      - brancheLibelle: ${eleveJson['brancheLibelle']}');
            print('   🖼️ Vérification du champ photo:');
            print('      - cheminphoto: ${eleveJson['cheminphoto']}');
            print('      - urlPhoto: ${eleveJson['urlPhoto']}');
            break;
          }
        }
        
        if (!foundTargetMatricule) {
          print('⚠️ Matricule 25125794Q non trouvé dans la liste des élèves');
        }
        
        // Logger les classeid des premiers élèves pour débogage
        if (data.isNotEmpty) {
          print('📋 Exemples de classeid des élèves:');
          for (int i = 0; i < (data.length > 3 ? 3 : data.length); i++) {
            final eleveJson = data[i] as Map<String, dynamic>;
            print('   - Élève ${i + 1}: matricule=${eleveJson['matriculeEleve']}, classeid=${eleveJson['classeid']}, brancheid=${eleveJson['brancheid']}');
          }
        }
        
        final eleves = data.map((json) => Eleve.fromJson(json as Map<String, dynamic>)).toList();
        
        // Vérifier l'élève avec le matricule 25125794Q après parsing
        try {
          final targetEleve = eleves.firstWhere(
            (e) => e.matriculeEleve == '25125794Q' || e.matriculeEleve.toUpperCase() == '25125794Q',
          );
          print('🎯 ÉLÈVE APRÈS PARSING - Matricule: ${targetEleve.matriculeEleve}');
          print('   - classeid final utilisé: ${targetEleve.classeid}');
          print('   - classe final utilisé: ${targetEleve.classe}');
        } catch (e) {
          // Élève non trouvé après parsing, déjà loggé avant
        }
        
        print('');
        print('═══════════════════════════════════════════════════════════');
        print('✅ FIN CHARGEMENT DES ÉLÈVES');
        print('═══════════════════════════════════════════════════════════');
        print('');
        
        return eleves;
      } else {
        throw Exception(
          'Erreur lors de la récupération des élèves: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des élèves: $e');
      throw Exception('Erreur lors de la récupération des élèves: $e');
    }
  }

  /// Récupère toutes les périodes
  /// 
  /// Endpoint: GET /periodes/list
  Future<List<Periode>> getAllPeriodes() async {
    try {
      final uri = Uri.parse('$_baseUrl/periodes/list');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Periode.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des périodes: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des périodes: $e');
    }
  }

  /// Recherche un élève par son matricule dans une école et une année
  /// 
  /// Retourne l'élève correspondant au matricule, ou null si non trouvé
  Future<Eleve?> findEleveByMatricule(int idEcole, int idAnnee, String matricule) async {
    try {
      print('🔍 ===== DÉBUT RECHERCHE ÉLÈVE =====');
      print('📝 Matricule recherché: $matricule');
      print('🏫 École ID: $idEcole');
      print('📅 Année ID: $idAnnee');
      print('🔗 Appel de getElevesByEcoleAndAnnee...');
      
      final eleves = await getElevesByEcoleAndAnnee(idEcole, idAnnee);
      print('📊 Nombre total d\'élèves récupérés: ${eleves.length}');
      
      print('🔎 Recherche du matricule "$matricule" dans la liste...');
      for (final eleve in eleves) {
        if (eleve.matriculeEleve.toLowerCase() == matricule.toLowerCase()) {
          print('✅ ===== ÉLÈVE TROUVÉ =====');
          print('   📝 Matricule: ${eleve.matriculeEleve}');
          print('   👤 Nom complet: ${eleve.fullName}');
          print('   📚 Classe ID (classeid): ${eleve.classeid}');
          print('   📚 Classe (libellé): ${eleve.classe}');
          print('   🆔 ID Élève Inscrit: ${eleve.idEleveInscrit}');
          print('   🆔 ID Inscription: ${eleve.inscriptionsidEleve}');
          print('   🖼️ URL Photo (cheminphoto): ${eleve.urlPhoto ?? "null"}');
          print('═══════════════════════════════════════════════════════════');
          print('');
          return eleve;
        }
      }
      print('❌ Aucun élève trouvé avec le matricule: $matricule');
      print('🔍 Liste des matricules disponibles (premiers 10):');
      for (int i = 0; i < (eleves.length > 10 ? 10 : eleves.length); i++) {
        print('   - ${eleves[i].matriculeEleve}');
      }
      print('═══════════════════════════════════════════════════════════');
      print('');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la recherche de l\'élève: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la recherche de l\'élève: $e');
    }
  }

  /// Récupère les matières d'une école et d'une classe
  /// 
  /// Endpoint: GET /imprimer-matrice-classe/matieres-ecole-web/{idEcole}/{classeId}
  /// 
  /// Exemple: GET /imprimer-matrice-classe/matieres-ecole-web/38/27159
  Future<List<Matiere>> getMatieresByEcoleAndClasse(int idEcole, int classeId) async {
    try {
      final uri = Uri.parse('$_baseUrl/imprimer-matrice-classe/matieres-ecole-web/$idEcole/$classeId');
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('📚 CHARGEMENT DES MATIÈRES');
      print('═══════════════════════════════════════════════════════════');
      print('🔗 URL complète de la ressource API:');
      print('   $uri');
      print('');
      print('📋 Paramètres utilisés:');
      print('   🏫 École ID: $idEcole');
      print('   📚 Classe ID (classeid): $classeId');
      print('═══════════════════════════════════════════════════════════');
      print('');
      
      // Headers selon la documentation de l'API
      final headers = {
        'Accept': 'application/octet-stream',
      };
      
      print('📡 Envoi de la requête...');
      final response = await http
          .get(uri, headers: headers)
          .timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        // L'API peut retourner application/octet-stream mais le contenu est du JSON
        final responseBody = response.body;
        print('📚 Taille de la réponse: ${responseBody.length} caractères');
        
        if (responseBody.isEmpty) {
          print('⚠️ Réponse vide pour les matières');
          return [];
        }
        
        try {
          final List<dynamic> data = json.decode(responseBody);
          print('');
          print('✅ ${data.length} matières chargées avec succès');
          print('');
          print('📋 Liste des matières:');
          for (int i = 0; i < data.length; i++) {
            final matiereJson = data[i] as Map<String, dynamic>;
            print('   ${i + 1}. ${matiereJson['libelle'] ?? 'N/A'} (ID: ${matiereJson['id'] ?? 'N/A'})');
          }
          print('');
          print('═══════════════════════════════════════════════════════════');
          print('✅ FIN CHARGEMENT DES MATIÈRES');
          print('═══════════════════════════════════════════════════════════');
          print('');
          final matieres = data.map((json) => Matiere.fromJson(json as Map<String, dynamic>)).toList();
          return matieres;
        } catch (e) {
          print('');
          print('❌ Erreur lors du parsing JSON: $e');
          print('❌ Contenu de la réponse (premiers 200 caractères):');
          print('   ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}');
          print('═══════════════════════════════════════════════════════════');
          print('');
          throw Exception('Erreur lors du parsing des matières: $e');
        }
      } else {
        print('');
        print('❌ Erreur HTTP ${response.statusCode}');
        print('❌ Corps de la réponse: ${response.body}');
        print('═══════════════════════════════════════════════════════════');
        print('');
        throw Exception(
          'Erreur lors de la récupération des matières: ${response.statusCode}. ${response.body}',
        );
      }
    } catch (e) {
      print('');
      print('❌ Exception lors de la récupération des matières: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la récupération des matières: $e');
    }
  }

  /// Récupère les notes d'une classe pour une année et une période
  /// 
  /// Endpoint: GET /notes/list-note-classe?anneeId={anneeId}&classeId={classeId}&periodeId={periodeId}
  Future<List<NoteClasseDto>> getNotesByClasse(int anneeId, int classeId, int periodeId) async {
    try {
      final uri = Uri.parse('$_baseUrl/notes/list-note-classe')
          .replace(queryParameters: {
        'anneeId': anneeId.toString(),
        'classeId': classeId.toString(),
        'periodeId': periodeId.toString(),
      });
      
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('📝 CHARGEMENT DES NOTES');
      print('═══════════════════════════════════════════════════════════');
      print('🔗 URL complète (dynamique selon la période sélectionnée):');
      print('   $uri');
      print('');
      print('📋 Paramètres utilisés dans l\'URL:');
      print('   📅 Année ID (anneeId): $anneeId');
      print('   📚 Classe ID (classeId): $classeId');
      print('   📆 Période ID (periodeId): $periodeId ⬅️ DYNAMIQUE');
      print('═══════════════════════════════════════════════════════════');
      print('');
      
      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ ${data.length} élève(s) avec notes récupéré(s)');
        print('');
        
        final notesDto = data.map((json) => NoteClasseDto.fromJson(json as Map<String, dynamic>)).toList();
        
        print('═══════════════════════════════════════════════════════════');
        print('✅ FIN CHARGEMENT DES NOTES');
        print('═══════════════════════════════════════════════════════════');
        print('');
        
        return notesDto;
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        throw Exception(
          'Erreur lors de la récupération des notes: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Exception lors de la récupération des notes: $e');
      throw Exception('Erreur lors de la récupération des notes: $e');
    }
  }

  /// Récupère les notes d'un élève spécifique par matricule, période et matière
  /// 
  /// Utilise la nouvelle ressource API: /notes/list-matricule-notes-moyennes/{matricule}/{anneeId}/{periodeId}
  /// Convertit la nouvelle structure en NoteApi pour compatibilité
  /// Retourne un NotesResult contenant les notes et les informations globales
  Future<NotesResult> getNotesByEleveMatricule(
    int anneeId,
    int classeId,
    int periodeId,
    String matricule,
    {String? matiereId}
  ) async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('📝 CHARGEMENT DES NOTES PAR MATRICULE');
      print('═══════════════════════════════════════════════════════════');
      print('🔍 Recherche des notes pour:');
      print('   🎫 Matricule: $matricule');
      print('   📅 Année ID: $anneeId');
      print('   📆 Période ID: $periodeId');
      print('   📚 Matière ID: ${matiereId ?? "Toutes"}');
      print('');
      
      // Utiliser la nouvelle ressource API
      final uri = Uri.parse('$_baseUrl/notes/list-matricule-notes-moyennes/$matricule/$anneeId/$periodeId');
      
      print('🔗 URL complète de la nouvelle ressource API:');
      print('   $uri');
      print('');
      
      final response = await http
          .get(uri, headers: _headers)
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('✅ Réponse reçue de la nouvelle ressource API');
        print('   Type de la réponse: ${responseData.runtimeType}');
        print('');
        
        // La nouvelle API retourne une liste (même si elle ne contient qu'un seul élément)
        List<NoteClasseDto> notesDtoList;
        if (responseData is List) {
          print('   📋 Réponse est une liste avec ${(responseData as List).length} élément(s)');
          notesDtoList = (responseData as List<dynamic>)
              .map((json) => NoteClasseDto.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (responseData is Map<String, dynamic>) {
          // Gérer le cas où c'est un objet unique (pour compatibilité)
          print('   📋 Réponse est un objet unique');
          notesDtoList = [NoteClasseDto.fromJson(responseData)];
        } else {
          throw Exception('Format de réponse inattendu: ${responseData.runtimeType}');
        }
        
        if (notesDtoList.isEmpty) {
          print('⚠️ Aucune donnée retournée par l\'API');
          return NotesResult(notes: []);
        }
        
        // Trouver l'élève correspondant au matricule (normalement il n'y en a qu'un)
        final eleveNotes = notesDtoList.firstWhere(
          (dto) => dto.eleve?.matricule.toLowerCase() == matricule.toLowerCase(),
          orElse: () => notesDtoList.first,
        );
        
        if (eleveNotes.eleve == null || eleveNotes.eleve!.matricule.toLowerCase() != matricule.toLowerCase()) {
          print('⚠️ Aucun élève trouvé avec le matricule: $matricule');
          print('   Matricule dans la réponse: ${eleveNotes.eleve?.matricule ?? "null"}');
          return NotesResult(notes: []);
        }
        
        print('✅ Élève trouvé: ${eleveNotes.eleve!.nom} ${eleveNotes.eleve!.prenom}');
        print('   📚 Nombre de matières: ${eleveNotes.matieres.length}');
        print('   📊 Moyenne générale: ${eleveNotes.moyenne ?? "N/A"}');
        print('   🏆 Rang global: ${eleveNotes.rang ?? "N/A"}');
        print('   📝 Observation: ${eleveNotes.observation ?? "N/A"}');
        print('   👥 Effectif de la classe: ${eleveNotes.classe?.effectif ?? "N/A"}');
        if (eleveNotes.noteMatiereMap != null) {
          print('   📋 noteMatiereMap disponible avec ${eleveNotes.noteMatiereMap!.length} entrées');
        }
        print('');
        
        // Log détaillé des matières
        for (var matiere in eleveNotes.matieres) {
          print('   📚 Matière: ${matiere.matiereLibelle}');
          print('      - ID: ${matiere.matiereId}');
          print('      - Moyenne: ${matiere.moyenne ?? "N/A"}');
          print('      - Coef: ${matiere.coef ?? "N/A"}');
          print('      - Rang: ${matiere.rang ?? "N/A"}');
          print('      - Appréciation: ${matiere.appreciation ?? "N/A"}');
          print('      - Nombre de notes: ${matiere.notes.length}');
          for (var note in matiere.notes) {
            print('         - Note: ${note.note ?? "N/A"} / ${note.noteSur ?? "N/A"}');
            print('           Type: ${note.evaluationType ?? "N/A"}');
            print('           Date: ${note.dateNote ?? "N/A"}');
            print('           Numéro: ${note.evaluationNumero ?? "N/A"}');
          }
        }
        print('');
        
        // Extraire les rangs par matière depuis noteMatiereMap
        final Map<String, int> rangsParMatiere = {};
        if (eleveNotes.noteMatiereMap != null) {
          eleveNotes.noteMatiereMap!.forEach((key, value) {
            if (value is Map<String, dynamic> && value['rang'] != null) {
              final matiereIdKey = key.toString();
              // Parser le rang qui peut être un int ou une string
              final rangValue = value['rang'];
              int? rang;
              if (rangValue is int) {
                rang = rangValue;
              } else if (rangValue is String) {
                rang = int.tryParse(rangValue);
              } else if (rangValue is num) {
                rang = rangValue.toInt();
              }
              if (rang != null) {
                rangsParMatiere[matiereIdKey] = rang;
                print('   📊 Matière $matiereIdKey: Rang $rang');
              }
            }
          });
        }
        print('');
        
        // Convertir en NoteApi
        final List<NoteApi> notesApi = [];
        
        for (final matiere in eleveNotes.matieres) {
          // Filtrer par matière si spécifiée
          if (matiereId != null && matiere.matiereId != matiereId) {
            continue;
          }
          
          // Récupérer le rang de la matière depuis noteMatiereMap ou depuis matiere.rang
          int? rangMatiere = matiere.rang;
          if (rangMatiere == null && rangsParMatiere.containsKey(matiere.matiereId)) {
            rangMatiere = rangsParMatiere[matiere.matiereId];
          }
          
          print('   📚 Matière: ${matiere.matiereLibelle} (ID: ${matiere.matiereId})');
          print('      - Moyenne: ${matiere.moyenne ?? "N/A"}');
          print('      - Coef: ${matiere.coef ?? "N/A"}');
          print('      - Rang: ${rangMatiere ?? "N/A"}');
          print('      - Nombre de notes: ${matiere.notes.length}');
          
          // Convertir chaque note détaillée en NoteApi
          for (final noteDetail in matiere.notes) {
            notesApi.add(NoteApi(
              id: noteDetail.id,
              matriculeEleve: eleveNotes.eleve!.matricule,
              nomEleve: eleveNotes.eleve!.nom,
              prenomEleve: eleveNotes.eleve!.prenom,
              matiereId: int.tryParse(matiere.matiereId), // Convertir string en int
              matiereLibelle: matiere.matiereLibelle,
              note: noteDetail.note,
              coef: matiere.coef,
              numeroDevoir: noteDetail.evaluationNumero,
              moyenne: matiere.moyenne,
              rang: rangMatiere, // Rang de la matière
              effectif: eleveNotes.classe?.effectif, // Effectif de la classe
              appreciation: matiere.appreciation,
              periodeId: periodeId,
              dateNote: noteDetail.dateNote,
              noteSur: noteDetail.noteSur, // Note sur depuis evaluation.noteSur
            ));
          }
        }
        
        print('✅ ${notesApi.length} note(s) convertie(s)');
        print('═══════════════════════════════════════════════════════════');
        print('');
        
        return NotesResult(
          notes: notesApi,
          moyenneGlobale: eleveNotes.moyenne,
          rangGlobal: eleveNotes.rang,
        );
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        throw Exception(
          'Erreur lors de la récupération des notes: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des notes de l\'élève: $e');
      print('═══════════════════════════════════════════════════════════');
      print('');
      throw Exception('Erreur lors de la récupération des notes de l\'élève: $e');
    }
  }

  /// Charge toutes les données pour une école : année, classes, périodes et élèves
  /// 
  /// Retourne un objet contenant toutes les données chargées
  Future<SchoolData> loadAllDataForEcole(int ecoleId) async {
    try {
      // Charge l'année scolaire ouverte
      final anneeScolaire = await getAnneeScolaireOuverte(ecoleId);
      final idAnnee = anneeScolaire.anneeOuverteCentraleId;

      // Charge les classes, périodes et élèves en parallèle
      final results = await Future.wait([
        getClassesByEcole(ecoleId),
        getAllPeriodes(),
        getElevesByEcoleAndAnnee(ecoleId, idAnnee),
      ]);

      final classes = results[0] as List<Classe>;
      final periodes = results[1] as List<Periode>;
      final eleves = results[2] as List<Eleve>;

      // Groupe les élèves par classe
      final Map<int, List<Eleve>> elevesParClasse = {};
      for (final eleve in eleves) {
        if (!elevesParClasse.containsKey(eleve.classeid)) {
          elevesParClasse[eleve.classeid] = [];
        }
        elevesParClasse[eleve.classeid]!.add(eleve);
      }

      return SchoolData(
        ecoleId: ecoleId,
        anneeScolaire: anneeScolaire,
        classes: classes,
        periodes: periodes,
        eleves: eleves,
        elevesParClasse: elevesParClasse,
      );
    } catch (e) {
      throw Exception('Erreur lors du chargement des données: $e');
    }
  }

  /// Enregistre un token FCM pour recevoir les notifications
  /// 
  /// Endpoint: POST /api/notifications/register-token
  /// Body: { 
  ///   "token": string, 
  ///   "userId": string, 
  ///   "deviceType": "android" | "ios",
  ///   "matricules": string[]
  /// }
  /// 
  /// Les matricules sont les identifiants des élèves pour lesquels ce token doit recevoir des notifications
  Future<bool> registerNotificationToken(
    String token,
    String userId, {
    String deviceType = 'android',
    List<String>? matricules,
  }) async {
    try {
      // Utiliser l'URL de base de l'API depuis AppConfig
      final baseUrl = AppConfig.API_BASE_URL;
      final uri = Uri.parse('$baseUrl/notifications/register-token');
      
      // Préparer le body avec les matricules (au moins un matricule requis)
      final body = {
        'token': token,
        'userId': userId,
        'deviceType': deviceType,
        'matricules': matricules ?? [],
      };
      
      print('📤 Enregistrement du token de notification');
      print('   URL: $uri');
      print('   UserId: $userId');
      print('   DeviceType: $deviceType');
      print('   Matricules: ${matricules?.length ?? 0}');
      
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Token de notification enregistré avec succès');
        final responseData = json.decode(response.body);
        if (responseData is Map && responseData.containsKey('matriculesCount')) {
          print('   Matricules associés: ${responseData['matriculesCount']}');
        }
        return true;
      } else {
        print('❌ Erreur lors de l\'enregistrement du token: ${response.statusCode}');
        print('   Réponse: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception lors de l\'enregistrement du token: $e');
      return false;
    }
  }

  /// Supprime un token FCM (déconnexion)
  /// 
  /// Endpoint: DELETE /api/notifications/unregister-token?userId={userId}&token={token}
  /// Utilise des query parameters au lieu d'un body JSON
  Future<bool> unregisterNotificationToken(String token, String userId) async {
    try {
      // Utiliser l'URL de base de l'API depuis AppConfig
      final baseUrl = AppConfig.API_BASE_URL;
      final uri = Uri.parse('$baseUrl/notifications/unregister-token').replace(
        queryParameters: {
          'userId': userId,
          'token': token,
        },
      );
      
      print('🗑️ Suppression du token de notification');
      print('   URL: $uri');
      print('   UserId: $userId');
      
      final response = await http
          .delete(
            uri,
            headers: _headers,
          )
          .timeout(AppConfig.API_TIMEOUT);

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Token de notification supprimé avec succès');
        return true;
      } else {
        print('❌ Erreur lors de la suppression du token: ${response.statusCode}');
        print('   Réponse: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception lors de la suppression du token: $e');
      return false;
    }
  }
}

/// Classe pour regrouper toutes les données d'une école
class SchoolData {
  final int ecoleId;
  final AnneeScolaire anneeScolaire;
  final List<Classe> classes;
  final List<Periode> periodes;
  final List<Eleve> eleves;
  final Map<int, List<Eleve>> elevesParClasse;

  SchoolData({
    required this.ecoleId,
    required this.anneeScolaire,
    required this.classes,
    required this.periodes,
    required this.eleves,
    required this.elevesParClasse,
  });

  /// Récupère les élèves d'une classe spécifique
  List<Eleve> getElevesByClasse(int classeId) {
    return elevesParClasse[classeId] ?? [];
  }
}


