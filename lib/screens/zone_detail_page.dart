import 'package:flutter/material.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/screens/zone_form_page.dart';

class ZoneDetailPage extends StatelessWidget {
  final Zone zone;
  final List<String> nomsAutres;

  const ZoneDetailPage({
    super.key,
    required this.zone,
    this.nomsAutres = const [],
  });

  Future<void> _modifier(BuildContext context) async {
    final nouvelle = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (context) => ZoneFormPage(
          zone: zone,
          nomsExistants: nomsAutres,
        ),
      ),
    );

    if (nouvelle == null || !context.mounted) return;

    // Deuxième pop : ferme la fiche et renvoie la zone modifiée à l'écran parent
    Navigator.pop(context, nouvelle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(zone.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _modifier(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(
                zone.culture.isNotEmpty ? zone.culture.substring(0, 2).toUpperCase() : 'ZS',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(zone.culture, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: const Icon(Icons.water_drop),
                    title: const Text('Humidité actuelle'),
                    trailing: Text('${zone.humidite}%'),
                  ),
                  LinearProgressIndicator(
                    value: zone.humidite / 100,
                    backgroundColor: Colors.grey[300],
                    color: zone.humidite < zone.seuil ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.warning),
                    title: const Text('Seuil critique'),
                    trailing: Text('${zone.seuil}%'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.power_settings_new),
                    title: const Text('État de la vanne'),
                    trailing: Text(
                      zone.vanneOuverte ? 'Ouverte' : 'Fermée',
                      style: TextStyle(
                        color: zone.vanneOuverte ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}