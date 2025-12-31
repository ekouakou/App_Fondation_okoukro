import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/adherent.dart';
import '../models/cotisation.dart';
import '../models/paiement.dart';
import '../models/benefice.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'okoukro_fondation.db';
  static const int _databaseVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Création de la table adhérents
    await db.execute('''
      CREATE TABLE adherents (
        id TEXT PRIMARY KEY,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        telephone TEXT NOT NULL UNIQUE,
        email TEXT,
        adresse TEXT,
        dateAdhesion TEXT NOT NULL,
        estActif INTEGER NOT NULL DEFAULT 1,
        photoUrl TEXT
      )
    ''');

    // Création de la table cotisations
    await db.execute('''
      CREATE TABLE cotisations (
        id TEXT PRIMARY KEY,
        adherentId TEXT NOT NULL,
        montantAnnuel INTEGER NOT NULL,
        annee INTEGER NOT NULL,
        dateModification TEXT NOT NULL,
        motifModification TEXT,
        FOREIGN KEY (adherentId) REFERENCES adherents (id),
        UNIQUE(adherentId, annee)
      )
    ''');

    // Création de la table paiements
    await db.execute('''
      CREATE TABLE paiements (
        id TEXT PRIMARY KEY,
        adherentId TEXT NOT NULL,
        annee INTEGER NOT NULL,
        montantVerse INTEGER NOT NULL,
        datePaiement TEXT NOT NULL,
        statut INTEGER NOT NULL,
        methode INTEGER NOT NULL,
        referenceTransaction TEXT,
        notes TEXT,
        FOREIGN KEY (adherentId) REFERENCES adherents (id)
      )
    ''');

    // Création de la table bénéfices
    await db.execute('''
      CREATE TABLE benefices (
        id TEXT PRIMARY KEY,
        annee INTEGER NOT NULL,
        montantTotal INTEGER NOT NULL,
        dateDistribution TEXT NOT NULL,
        description TEXT,
        estDistribue INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Création de la table parts bénéfices
    await db.execute('''
      CREATE TABLE parts_benefices (
        adherentId TEXT NOT NULL,
        beneficeId TEXT NOT NULL,
        montantPart INTEGER NOT NULL,
        pourcentage REAL NOT NULL,
        totalCotisationsAdherent INTEGER NOT NULL,
        PRIMARY KEY (adherentId, beneficeId),
        FOREIGN KEY (adherentId) REFERENCES adherents (id),
        FOREIGN KEY (beneficeId) REFERENCES benefices (id)
      )
    ''');

    // Création des index pour optimiser les performances
    await db.execute('CREATE INDEX idx_cotisations_adherent ON cotisations(adherentId)');
    await db.execute('CREATE INDEX idx_cotisations_annee ON cotisations(annee)');
    await db.execute('CREATE INDEX idx_paiements_adherent ON paiements(adherentId)');
    await db.execute('CREATE INDEX idx_paiements_annee ON paiements(annee)');
    await db.execute('CREATE INDEX idx_benefices_annee ON benefices(annee)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations de base de données ici
    if (oldVersion < newVersion) {
      // Ajouter les nouvelles colonnes ou tables si nécessaire
    }
  }

  // ===== OPÉRATIONS ADHÉRENTS =====
  
  static Future<int> insertAdherent(Adherent adherent) async {
    final db = await database;
    return await db.insert('adherents', adherent.toMap());
  }

  static Future<List<Adherent>> getAllAdherents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('adherents', orderBy: 'nom, prenom');
    return List.generate(maps.length, (i) => Adherent.fromMap(maps[i]));
  }

  static Future<Adherent?> getAdherentById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'adherents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Adherent.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateAdherent(Adherent adherent) async {
    final db = await database;
    return await db.update(
      'adherents',
      adherent.toMap(),
      where: 'id = ?',
      whereArgs: [adherent.id],
    );
  }

  static Future<int> deleteAdherent(String id) async {
    final db = await database;
    return await db.delete('adherents', where: 'id = ?', whereArgs: [id]);
  }

  // ===== OPÉRATIONS COTISATIONS =====
  
  static Future<int> insertCotisation(Cotisation cotisation) async {
    final db = await database;
    return await db.insert('cotisations', cotisation.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Cotisation>> getAllCotisations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cotisations', orderBy: 'annee DESC, adherentId');
    return List.generate(maps.length, (i) => Cotisation.fromMap(maps[i]));
  }

  static Future<List<Cotisation>> getCotisationsByAdherent(String adherentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cotisations',
      where: 'adherentId = ?',
      whereArgs: [adherentId],
      orderBy: 'annee DESC',
    );
    return List.generate(maps.length, (i) => Cotisation.fromMap(maps[i]));
  }

  static Future<Cotisation?> getCotisationByAdherentAnnee(String adherentId, int annee) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cotisations',
      where: 'adherentId = ? AND annee = ?',
      whereArgs: [adherentId, annee],
    );
    if (maps.isNotEmpty) {
      return Cotisation.fromMap(maps.first);
    }
    return null;
  }

  static Future<int> updateCotisation(Cotisation cotisation) async {
    final db = await database;
    return await db.update(
      'cotisations',
      cotisation.toMap(),
      where: 'id = ?',
      whereArgs: [cotisation.id],
    );
  }

  // ===== OPÉRATIONS PAIEMENTS =====
  
  static Future<int> insertPaiement(Paiement paiement) async {
    final db = await database;
    return await db.insert('paiements', paiement.toMap());
  }

  static Future<List<Paiement>> getAllPaiements() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('paiements', orderBy: 'datePaiement DESC');
    return List.generate(maps.length, (i) => Paiement.fromMap(maps[i]));
  }

  static Future<List<Paiement>> getPaiementsByAdherent(String adherentId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'paiements',
      where: 'adherentId = ?',
      whereArgs: [adherentId],
      orderBy: 'datePaiement DESC',
    );
    return List.generate(maps.length, (i) => Paiement.fromMap(maps[i]));
  }

  static Future<List<Paiement>> getPaiementsByAnnee(int annee) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'paiements',
      where: 'annee = ?',
      whereArgs: [annee],
      orderBy: 'datePaiement DESC',
    );
    return List.generate(maps.length, (i) => Paiement.fromMap(maps[i]));
  }

  // ===== OPÉRATIONS BÉNÉFICES =====
  
  static Future<int> insertBenefice(Benefice benefice) async {
    final db = await database;
    return await db.insert('benefices', benefice.toMap());
  }

  static Future<List<Benefice>> getAllBenefices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('benefices', orderBy: 'annee DESC');
    return List.generate(maps.length, (i) => Benefice.fromMap(maps[i]));
  }

  static Future<int> updateBenefice(Benefice benefice) async {
    final db = await database;
    return await db.update(
      'benefices',
      benefice.toMap(),
      where: 'id = ?',
      whereArgs: [benefice.id],
    );
  }

  // ===== OPÉRATIONS PARTS BÉNÉFICES =====
  
  static Future<void> insertPartsBenefices(List<PartBenefice> parts) async {
    final db = await database;
    final batch = db.batch();
    
    for (var part in parts) {
      batch.insert('parts_benefices', part.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit();
  }

  static Future<List<PartBenefice>> getPartsByBenefice(String beneficeId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parts_benefices',
      where: 'beneficeId = ?',
      whereArgs: [beneficeId],
      orderBy: 'montantPart DESC',
    );
    return List.generate(maps.length, (i) => PartBenefice.fromMap(maps[i]));
  }

  // ===== UTILITAIRES =====
  
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('parts_benefices');
    await db.delete('paiements');
    await db.delete('cotisations');
    await db.delete('benefices');
    await db.delete('adherents');
  }

  static Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
