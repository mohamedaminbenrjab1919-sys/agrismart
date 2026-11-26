import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:agrismart/models/recolte.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecoltesProvider extends ChangeNotifier {
  final List<Recolte> _recoltes = [];
  bool _estCharge = false;
  String? _erreur;
  static const _storageKey = 'agrismart_recoltes';

  RecoltesProvider() {
    charger();
  }

  List<Recolte> get recoltes => List.unmodifiable(_recoltes);
  bool get estCharge => _estCharge;
  String? get erreur => _erreur;

  double get quantiteTotale {
    return _recoltes.fold(0, (total, recolte) => total + recolte.quantite);
  }

  int get nombreRecoltes => _recoltes.length;

  double quantiteParCulture(String culture) {
    return _recoltes
        .where((recolte) => recolte.culture == culture)
        .fold(0, (total, recolte) => total + recolte.quantite);
  }

  List<String> get cultures =>
      _recoltes.map((recolte) => recolte.culture).toSet().toList();

  Future<void> charger() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final donnees = preferences.getString(_storageKey);
      if (donnees != null && donnees.isNotEmpty) {
        final liste = jsonDecode(donnees) as List<dynamic>;
        _recoltes
          ..clear()
          ..addAll(
            liste
                .map(
                  (item) =>
                      Recolte.fromJson(Map<String, dynamic>.from(item as Map)),
                )
                .toList(),
          );
        _trier();
      }
      _erreur = null;
    } catch (_) {
      _erreur = 'Impossible de charger les récoltes enregistrées.';
    } finally {
      _estCharge = true;
      notifyListeners();
    }
  }

  Future<bool> _sauvegarder() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final donnees = jsonEncode(
        _recoltes.map((recolte) => recolte.toJson()).toList(),
      );
      final sauvegarde = await preferences.setString(_storageKey, donnees);
      _erreur = sauvegarde
          ? null
          : 'Impossible d’enregistrer les modifications.';
      notifyListeners();
      return sauvegarde;
    } catch (_) {
      _erreur = 'Impossible d’enregistrer les modifications.';
      notifyListeners();
      return false;
    }
  }

  void _trier() {
    _recoltes.sort((a, b) => b.dateRecolte.compareTo(a.dateRecolte));
  }

  Future<bool> ajouter(Recolte recolte) async {
    _recoltes.add(recolte);
    _trier();
    notifyListeners();
    return _sauvegarder();
  }

  Future<bool> modifier(Recolte ancienne, Recolte nouvelle) async {
    final index = _recoltes.indexWhere((recolte) => recolte.id == ancienne.id);
    if (index == -1) return false;
    _recoltes[index] = nouvelle;
    _trier();
    notifyListeners();
    return _sauvegarder();
  }

  Future<bool> supprimer(String id) async {
    _recoltes.removeWhere((recolte) => recolte.id == id);
    notifyListeners();
    return _sauvegarder();
  }
}
