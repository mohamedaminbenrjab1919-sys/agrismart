import 'dart:async';
import 'package:agrismart/models/utilisateur.dart';
import 'package:agrismart/services/auth_service.dart';

class AuthLocaleService implements AuthService {
  final Map<String, String> _comptes = {'demo@agrismart.tn': '123456'};
  final Map<String, String> _noms = {'demo@agrismart.tn': 'Exploitation Démo'};
  final StreamController<Utilisateur?> _controller =
  StreamController<Utilisateur?>.broadcast();
  Utilisateur? _courant;

  @override
  Stream<Utilisateur?> get utilisateur async* {
    yield _courant;
    yield* _controller.stream;
  }

  void _definir(Utilisateur? u) {
    _courant = u;
    _controller.add(u);
  }

  @override
  Future<void> connexion(String email, String motDePasse) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final cle = email.trim().toLowerCase();
    if (_comptes[cle] != motDePasse) {
      throw const AuthException('Email ou mot de passe incorrect');
    }
    _definir(Utilisateur(uid: cle, email: cle, nom: _noms[cle]));
  }

  @override
  Future<void> inscription(String email, String motDePasse,
      {String? nom}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final cle = email.trim().toLowerCase();
    if (_comptes.containsKey(cle)) {
      throw const AuthException('Un compte existe déjà avec cet email');
    }
    _comptes[cle] = motDePasse;
    final n = (nom ?? '').trim();
    if (n.isNotEmpty) {
      _noms[cle] = n;
    }
    _definir(Utilisateur(uid: cle, email: cle, nom: _noms[cle]));
  }

  @override
  Future<void> mettreAJourNom(String nom) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final courant = _courant;
    if (courant == null) {
      throw const AuthException('Aucun utilisateur connecté');
    }
    final n = nom.trim();
    _noms[courant.email] = n;
    _definir(Utilisateur(uid: courant.uid, email: courant.email, nom: n));
  }

  @override
  Future<void> reinitialiserMotDePasse(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> supprimerCompte() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final courant = _courant;
    if (courant != null) {
      _comptes.remove(courant.email);
      _noms.remove(courant.email);
    }
    _definir(null);
  }

  @override
  Future<void> deconnexion() async {
    _definir(null);
  }
}