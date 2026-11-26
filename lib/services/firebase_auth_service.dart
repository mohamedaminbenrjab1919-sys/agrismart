import 'package:firebase_auth/firebase_auth.dart';
import 'package:agrismart/models/utilisateur.dart';
import 'package:agrismart/services/auth_service.dart';

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Utilisateur? _mapperUtilisateur(User? u) {
    if (u == null) return null;
    return Utilisateur(
      uid: u.uid,
      email: u.email ?? '',
      nom: u.displayName,
    );
  }

  @override
  Stream<Utilisateur?> get utilisateur =>
      _auth.userChanges().map(_mapperUtilisateur);

  @override
  Future<void> connexion(String email, String motDePasse) {
    return _executer(() => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: motDePasse,
    ));
  }

  @override
  Future<void> inscription(String email, String motDePasse, {String? nom}) {
    return _executer(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: motDePasse,
      );
      final n = (nom ?? '').trim();
      if (n.isNotEmpty && cred.user != null) {
        await cred.user!.updateDisplayName(n);
        await cred.user!.reload();
      }
    });
  }

  @override
  Future<void> mettreAJourNom(String nom) {
    return _executer(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthException('Aucun utilisateur connecté');
      }
      await user.updateDisplayName(nom.trim());
      await user.reload();
    });
  }

  @override
  Future<void> reinitialiserMotDePasse(String email) {
    return _executer(
          () => _auth.sendPasswordResetEmail(email: email.trim()),
    );
  }

  @override
  Future<void> supprimerCompte() {
    return _executer(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthException('Aucun utilisateur connecté');
      }
      await user.delete();
    });
  }

  @override
  Future<void> deconnexion() => _auth.signOut();

  Future<void> _executer(Future<void> Function() operation) async {
    try {
      await operation();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traduire(e.code));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Une erreur est survenue');
    }
  }

  String _traduire(String code) {
    switch (code) {
      case 'invalid-email':
        return "L'adresse email n'est pas valide";
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum)';
      case 'network-request-failed':
        return 'Pas de connexion Internet';
      case 'too-many-requests':
        return 'Trop de tentatives, réessayez plus tard';
      case 'requires-recent-login':
        return 'Veuillez vous reconnecter avant de supprimer votre compte';
      default:
        return "Erreur d'authentification ($code)";
    }
  }
}