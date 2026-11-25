import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/widgets/fiche_exploitation.dart';
import 'package:agrismart/widgets/resume_exploitation.dart';
import 'package:agrismart/widgets/zone_card.dart';
import 'package:agrismart/screens/zone_form_page.dart';
import 'package:agrismart/screens/zone_detail_page.dart';

class ZonesPage extends StatelessWidget {
  const ZonesPage({super.key});

  Future<void> _supprimerZone(BuildContext context, Zone zone) async {
    final provider = context.read<ZonesProvider>();
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la zone'),
        content: Text('Voulez-vous vraiment supprimer la zone "${zone.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmer == true && context.mounted) {
      provider.supprimer(zone);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Zone "${zone.nom}" supprimée')),
      );
    }
  }

  Future<void> _ouvrirFormulaire(BuildContext context, {Zone? zone}) async {
    final provider = context.read<ZonesProvider>();
    final nomsExistants = provider.noms(sauf: zone);

    final nouvelleZone = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (context) => ZoneFormPage(
          zone: zone,
          nomsExistants: nomsExistants,
        ),
      ),
    );

    if (nouvelleZone == null || !context.mounted) return;

    if (zone == null) {
      provider.ajouter(nouvelleZone);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone ajoutée avec succès')),
      );
    } else {
      provider.remplacer(zone, nouvelleZone);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zone modifiée avec succès')),
      );
    }
  }

  Future<void> _ouvrirDetail(BuildContext context, Zone zone) async {
    final provider = context.read<ZonesProvider>();
    final nomsAutres = provider.noms(sauf: zone);

    final zoneModifiee = await Navigator.push<Zone>(
      context,
      MaterialPageRoute(
        builder: (context) => ZoneDetailPage(zone: zone, nomsAutres: nomsAutres),
      ),
    );

    if (zoneModifiee != null && context.mounted) {
      provider.remplacer(zone, zoneModifiee);
    }
  }

  Widget _carte(BuildContext context, Zone zone) {
    final provider = context.read<ZonesProvider>();
    return ZoneCard(
      zone: zone,
      onAugmenter: () => provider.modifierHumidite(zone, 5),
      onDiminuer: () => provider.modifierHumidite(zone, -5),
      onTap: () => _ouvrirDetail(context, zone),
      onLongPress: () => _supprimerZone(context, zone),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Écoute de la liste des zones depuis le Provider
    final zones = context.watch<ZonesProvider>().zones;
    final double moyenne = humiditeMoyenne(zones);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('AgriSmart - Zones'),
      ),
      body: Column(
        children: [
          FicheExploitation(humiditeMoyenne: moyenne),
          ResumeExploitation(zones: zones),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 600) {
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.8,
                    ),
                    itemCount: zones.length,
                    itemBuilder: (context, index) => _carte(context, zones[index]),
                  );
                }
                return ListView.builder(
                  itemCount: zones.length,
                  itemBuilder: (context, index) => _carte(context, zones[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ouvrirFormulaire(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}