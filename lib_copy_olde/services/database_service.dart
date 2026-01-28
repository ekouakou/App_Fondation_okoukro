import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/child.dart';

/// Service de gestion de la base de données locale SQLite
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  factory DatabaseService() => instance;
  DatabaseService._internal();

  static Database? _database;

  /// Récupère l'instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données et crée les tables
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'pouls_ecole_parent.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crée les tables lors de la première création de la base de données
  Future<void> _onCreate(Database db, int version) async {
    // Table des utilisateurs
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        email TEXT,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        smsCredits INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Table des enfants
    await db.execute('''
      CREATE TABLE children (
        id TEXT PRIMARY KEY,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        establishment TEXT NOT NULL,
        grade TEXT NOT NULL,
        photoUrl TEXT,
        parentId TEXT NOT NULL,
        matricule TEXT,
        ecoleId INTEGER,
        ecoleName TEXT,
        classeId INTEGER,
        classeName TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        FOREIGN KEY (parentId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Table pour suivre les notes consultées (Vue)
    await db.execute('''
      CREATE TABLE notes_viewed (
        id TEXT PRIMARY KEY,
        childId TEXT NOT NULL,
        matiereId INTEGER NOT NULL,
        periodeId INTEGER NOT NULL,
        anneeId INTEGER NOT NULL,
        viewedAt INTEGER NOT NULL,
        FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_notes_viewed_child ON notes_viewed(childId, matiereId, periodeId)');

    // Table des notifications FCM
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        data TEXT,
        timestamp INTEGER NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        sender TEXT,
        parentId TEXT,
        FOREIGN KEY (parentId) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_children_parentId ON children(parentId)');
    await db.execute('CREATE INDEX idx_children_matricule ON children(matricule)');
    await db.execute('CREATE INDEX idx_notifications_parentId ON notifications(parentId)');
    await db.execute('CREATE INDEX idx_notifications_timestamp ON notifications(timestamp DESC)');
    await db.execute('CREATE INDEX idx_notifications_isRead ON notifications(isRead)');
  }

  /// Met à jour la base de données lors d'un changement de version
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajouter la table notes_viewed si elle n'existe pas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notes_viewed (
          id TEXT PRIMARY KEY,
          childId TEXT NOT NULL,
          matiereId INTEGER NOT NULL,
          periodeId INTEGER NOT NULL,
          anneeId INTEGER NOT NULL,
          viewedAt INTEGER NOT NULL,
          FOREIGN KEY (childId) REFERENCES children(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notes_viewed_child ON notes_viewed(childId, matiereId, periodeId)');
    }
    if (oldVersion < 3) {
      // Ajouter la table notifications si elle n'existe pas
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          data TEXT,
          timestamp INTEGER NOT NULL,
          isRead INTEGER NOT NULL DEFAULT 0,
          sender TEXT,
          parentId TEXT,
          FOREIGN KEY (parentId) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_parentId ON notifications(parentId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_timestamp ON notifications(timestamp DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_notifications_isRead ON notifications(isRead)');
    }
  }

  /// Sauvegarde ou met à jour un utilisateur
  Future<void> saveUser(User user) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'users',
      {
        'id': user.id,
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'phone': user.phone,
        'smsCredits': user.smsCredits,
        'createdAt': now,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère un utilisateur par son ID
  Future<User?> getUserById(String userId) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;

    return User.fromJson(Map<String, dynamic>.from(maps.first));
  }

  /// Récupère un utilisateur par son numéro de téléphone
  Future<User?> getUserByPhone(String phone) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [phone],
    );

    if (maps.isEmpty) return null;

    return User.fromJson(Map<String, dynamic>.from(maps.first));
  }

  /// Met à jour les crédits SMS d'un utilisateur
  Future<void> updateUserSmsCredits(String userId, int credits) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'users',
      {
        'smsCredits': credits,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Sauvegarde ou met à jour un enfant
  Future<void> saveChild(Child child, {
    String? matricule,
    int? ecoleId,
    String? ecoleName,
    int? classeId,
    String? classeName,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.insert(
      'children',
      {
        'id': child.id,
        'firstName': child.firstName,
        'lastName': child.lastName,
        'establishment': child.establishment,
        'grade': child.grade,
        'photoUrl': child.photoUrl,
        'parentId': child.parentId,
        'matricule': matricule,
        'ecoleId': ecoleId,
        'ecoleName': ecoleName,
        'classeId': classeId,
        'classeName': classeName,
        'createdAt': now,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère tous les enfants d'un parent
  Future<List<Child>> getChildrenByParent(String parentId) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) {
      return Child.fromJson(Map<String, dynamic>.from(map));
    }).toList();
  }

  /// Récupère un enfant par son ID
  Future<Child?> getChildById(String childId) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'id = ?',
      whereArgs: [childId],
    );

    if (maps.isEmpty) return null;

    return Child.fromJson(Map<String, dynamic>.from(maps.first));
  }

  /// Récupère les informations complètes d'un enfant (avec ecoleId et classeId)
  Future<Map<String, dynamic>?> getChildInfoById(String childId) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'id = ?',
      whereArgs: [childId],
    );

    if (maps.isEmpty) return null;

    return Map<String, dynamic>.from(maps.first);
  }

  /// Récupère les informations complètes de tous les enfants d'un parent (avec matricule)
  Future<List<Map<String, dynamic>>> getChildrenInfoByParent(String parentId) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => Map<String, dynamic>.from(map)).toList();
  }

  /// Récupère un enfant par son matricule
  Future<Child?> getChildByMatricule(String matricule) async {
    final db = await database;
    final maps = await db.query(
      'children',
      where: 'matricule = ?',
      whereArgs: [matricule],
    );

    if (maps.isEmpty) return null;

    return Child.fromJson(Map<String, dynamic>.from(maps.first));
  }

  /// Met à jour la photo d'un enfant
  Future<void> updateChildPhoto(String childId, String? photoUrl) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'children',
      {
        'photoUrl': photoUrl,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [childId],
    );
    print('✅ Photo mise à jour pour l\'enfant $childId: ${photoUrl ?? "null"}');
  }

  /// Supprime un enfant
  Future<void> deleteChild(String childId) async {
    final db = await database;
    await db.delete(
      'children',
      where: 'id = ?',
      whereArgs: [childId],
    );
  }

  /// Supprime tous les enfants d'un parent
  Future<void> deleteChildrenByParent(String parentId) async {
    final db = await database;
    await db.delete(
      'children',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
  }

  /// Supprime un utilisateur et tous ses enfants
  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    // Les enfants seront supprimés automatiquement grâce à ON DELETE CASCADE
  }

  /// Marque une note comme consultée (Vue)
  Future<void> markNoteAsViewed(String childId, int matiereId, int periodeId, int anneeId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = '${childId}_${matiereId}_${periodeId}_${anneeId}';
    
    await db.insert(
      'notes_viewed',
      {
        'id': id,
        'childId': childId,
        'matiereId': matiereId,
        'periodeId': periodeId,
        'anneeId': anneeId,
        'viewedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Vérifie si une note a été consultée
  Future<bool> isNoteViewed(String childId, int matiereId, int periodeId, int anneeId) async {
    final db = await database;
    final id = '${childId}_${matiereId}_${periodeId}_${anneeId}';
    
    final maps = await db.query(
      'notes_viewed',
      where: 'id = ?',
      whereArgs: [id],
    );

    return maps.isNotEmpty;
  }

  /// Sauvegarde une notification FCM
  Future<void> saveNotification({
    required String id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required DateTime timestamp,
    String? sender,
    String? parentId,
  }) async {
    final db = await database;
    await db.insert(
      'notifications',
      {
        'id': id,
        'title': title,
        'body': body,
        'data': data != null ? jsonEncode(data) : null,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'isRead': 0,
        'sender': sender,
        'parentId': parentId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère toutes les notifications d'un parent
  Future<List<Map<String, dynamic>>> getNotificationsByParent(String parentId) async {
    final db = await database;
    final maps = await db.query(
      'notifications',
      where: 'parentId = ?',
      whereArgs: [parentId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) {
      final result = Map<String, dynamic>.from(map);
      // Parser le champ data si présent
      if (result['data'] != null && result['data'] is String) {
        try {
          result['data'] = jsonDecode(result['data'] as String);
        } catch (e) {
          result['data'] = null;
        }
      }
      // Convertir isRead de INTEGER à bool
      result['isRead'] = (result['isRead'] as int? ?? 0) == 1;
      return result;
    }).toList();
  }

  /// Marque une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Marque toutes les notifications d'un parent comme lues
  Future<void> markAllNotificationsAsRead(String parentId) async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'parentId = ? AND isRead = ?',
      whereArgs: [parentId, 0],
    );
  }

  /// Récupère le nombre de notifications non lues d'un parent
  Future<int> getUnreadNotificationsCount(String parentId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notifications WHERE parentId = ? AND isRead = 0',
      [parentId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Supprime une notification
  Future<void> deleteNotification(String notificationId) async {
    final db = await database;
    await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Supprime toutes les notifications d'un parent
  Future<void> deleteNotificationsByParent(String parentId) async {
    final db = await database;
    await db.delete(
      'notifications',
      where: 'parentId = ?',
      whereArgs: [parentId],
    );
  }

  /// Ferme la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

