import 'package:flutter_test/flutter_test.dart';
import 'package:agrismart/models/recolte.dart';
import 'package:agrismart/providers/recoltes_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Recolte peut être sérialisée pour la sauvegarde', () {
    final recolte = Recolte(
      id: '1',
      nomZone: 'Zone Nord',
      culture: 'Blé',
      quantite: 125.5,
      dateRecolte: DateTime(2026, 5, 10),
      qualite: 'Bonne',
    );

    final restoree = Recolte.fromJson(recolte.toJson());

    expect(restoree.id, '1');
    expect(restoree.nomZone, 'Zone Nord');
    expect(restoree.culture, 'Blé');
    expect(restoree.quantite, 125.5);
    expect(restoree.qualite, 'Bonne');
  });

  test('Recolte.copyWith conserve les valeurs non modifiées', () {
    final recolte = Recolte(
      id: '2',
      nomZone: 'Zone Sud',
      culture: 'Tomate',
      quantite: 80,
      dateRecolte: DateTime(2026, 6, 1),
      qualite: 'Excellente',
    );

    final modifiee = recolte.copyWith(quantite: 95);

    expect(modifiee.quantite, 95);
    expect(modifiee.culture, 'Tomate');
    expect(modifiee.nomZone, 'Zone Sud');
  });

  test('Le provider calcule le total et agrège les cultures', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = RecoltesProvider();
    await provider.charger();

    await provider.ajouter(
      Recolte(
        id: '1',
        nomZone: 'Nord',
        culture: 'Blé',
        quantite: 100,
        dateRecolte: DateTime(2026, 5, 1),
        qualite: 'Bonne',
      ),
    );
    await provider.ajouter(
      Recolte(
        id: '2',
        nomZone: 'Sud',
        culture: 'Blé',
        quantite: 50,
        dateRecolte: DateTime(2026, 6, 1),
        qualite: 'Excellente',
      ),
    );
    await provider.ajouter(
      Recolte(
        id: '3',
        nomZone: 'Est',
        culture: 'Tomate',
        quantite: 25,
        dateRecolte: DateTime(2026, 7, 1),
        qualite: 'Moyenne',
      ),
    );

    expect(provider.nombreRecoltes, 3);
    expect(provider.quantiteTotale, 175);
    expect(provider.quantiteParCulture('Blé'), 150);
    expect(provider.recoltes.first.id, '3');

    await provider.supprimer('2');
    expect(provider.nombreRecoltes, 2);
    expect(provider.quantiteTotale, 125);
  });
}
