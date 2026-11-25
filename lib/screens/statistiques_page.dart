import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/widgets/meteo_card.dart';

class StatistiquesPage extends StatelessWidget {
  const StatistiquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération des zones via Provider (watch pour écouter les changements)
    final zones = context.watch<ZonesProvider>().zones;

    // Tri des zones de la plus sèche à la plus humide
    final zonesTriees = [...zones]
      ..sort((a, b) => a.humidite.compareTo(b.humidite));
    final int totalZones = zones.length;
    final int zonesAIrriguer = zones.where((z) => z.besoinIrrigation).length;
    final int pourcentage =
    totalZones > 0 ? (zonesAIrriguer * 100 / totalZones).round() : 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Statistiques'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const MeteoCard(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('État Global',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text('Total des zones : $totalZones'),
                  Text(
                      'Zones nécessitant une irrigation : $zonesAIrriguer ($pourcentage%)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Zones par humidité (plus sèche en premier)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...zonesTriees.map(
                (z) => ListTile(
              title: Text(z.nom),
              subtitle: Text('Culture : ${z.culture}'),
              trailing: Text(
                '${z.humidite}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: z.humidite < z.seuil ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}