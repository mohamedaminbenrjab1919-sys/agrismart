import 'package:flutter/foundation.dart';
import 'package:agrismart/data/jeu_de_donnees.dart';
import 'package:agrismart/models/zone.dart';

class ZonesProvider extends ChangeNotifier {
  final List<Zone> _zones = jeuDeDonnees();

  // Copie en lecture seule pour protéger la liste
  List<Zone> get zones => List.unmodifiable(_zones);

  int get nombre => _zones.length;

  int get nombreAIrriguer => _zones.where((z) => z.besoinIrrigation).length;

  // Noms des zones (sauf une), pour refuser un doublon dans le formulaire
  List<String> noms({Zone? sauf}) {
    return _zones.where((z) => z != sauf).map((z) => z.nom).toList();
  }

  void modifierHumidite(Zone zone, double delta) {
    zone.humidite = (zone.humidite + delta).clamp(0, 100).toDouble();
    notifyListeners();
  }

  void ajouter(Zone zone) {
    _zones.add(zone);
    notifyListeners();
  }

  void remplacer(Zone ancienne, Zone nouvelle) {
    final index = _zones.indexOf(ancienne);
    if (index == -1) return;
    _zones[index] = nouvelle;
    notifyListeners();
  }

  void supprimer(Zone zone) {
    _zones.remove(zone);
    notifyListeners();
  }
}