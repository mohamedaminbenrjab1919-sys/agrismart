import 'package:flutter/foundation.dart';
import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/models/zone.dart';

class ZonesProvider extends ChangeNotifier {
  final Map<String, List<Zone>> _zonesParUid = {};
  String? _uidActif;

  ZonesProvider({String? uidInitial}) {
    definirUtilisateur(uidInitial);
  }

  void definirUtilisateur(String? uid) {
    final cle = (uid == null || uid.trim().isEmpty) ? '_invite' : uid.trim();
    if (_uidActif == cle && _zonesParUid.containsKey(cle)) return;
    _uidActif = cle;
    _zonesParUid.putIfAbsent(cle, () => jeuDeDonnees());
    notifyListeners();
  }

  List<Zone> get _zonesCourantes {
    final cle = _uidActif ?? '_invite';
    return _zonesParUid.putIfAbsent(cle, () => jeuDeDonnees());
  }

  // Copie en lecture seule pour protéger la liste
  List<Zone> get zones => List.unmodifiable(_zonesCourantes);

  int get nombre => _zonesCourantes.length;

  int get nombreAIrriguer =>
      _zonesCourantes.where((z) => z.besoinIrrigation).length;

  // Noms des zones (sauf une), pour refuser un doublon dans le formulaire
  List<String> noms({Zone? sauf}) {
    return _zonesCourantes.where((z) => z != sauf).map((z) => z.nom).toList();
  }

  void modifierHumidite(Zone zone, double delta) {
    zone.humidite = (zone.humidite + delta).clamp(0, 100).toDouble();
    notifyListeners();
  }

  void ajouter(Zone zone) {
    _zonesCourantes.add(zone);
    notifyListeners();
  }

  void remplacer(Zone ancienne, Zone nouvelle) {
    final liste = _zonesCourantes;
    final index = liste.indexOf(ancienne);
    if (index == -1) return;
    liste[index] = nouvelle;
    notifyListeners();
  }

  void supprimer(Zone zone) {
    _zonesCourantes.remove(zone);
    notifyListeners();
  }
}