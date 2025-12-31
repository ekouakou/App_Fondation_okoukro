import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthService() {
    // Écouter les changements d'état d'authentification
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Connexion avec email et mot de passe
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Une erreur est survenue: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Création de compte avec email et mot de passe
  Future<bool> createUserWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Une erreur est survenue: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _setError('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }

  // Réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Une erreur est survenue: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Vérifier si l'email est vérifié
  bool get isEmailVerified => _user?.emailVerified ?? false;

  // Envoyer l'email de vérification
  Future<bool> sendEmailVerification() async {
    try {
      await _user?.sendEmailVerification();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'envoi de l\'email de vérification: ${e.toString()}');
      return false;
    }
  }

  // Méthodes privées pour gérer l'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Méthode publique pour effacer l'erreur
  void clearError() {
    _clearError();
  }

  // Obtenir les messages d'erreur en français
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'user-not-found':
        return 'Utilisateur non trouvé.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-email':
        return 'Email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard.';
      case 'operation-not-allowed':
        return 'Opération non autorisée.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion.';
      default:
        return 'Une erreur est survenue: $code';
    }
  }
}
