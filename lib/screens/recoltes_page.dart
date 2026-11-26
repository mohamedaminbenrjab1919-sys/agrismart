import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:agrismart/providers/recoltes_provider.dart';
import 'package:agrismart/screens/recolte_form_page.dart';
import 'package:agrismart/models/recolte.dart';

class RecoltesPage extends StatelessWidget {
  const RecoltesPage({super.key});

  Future<void> _ouvrirFormulaire(
    BuildContext context, {
    Recolte? recolte,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecolteFormPage(recolte: recolte)),
    );
  }

  Future<void> _supprimer(
    BuildContext context,
    RecoltesProvider provider,
    Recolte recolte,
  ) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la récolte'),
        content: Text(
          'Voulez-vous supprimer la récolte de ${recolte.culture} '
          '(${recolte.quantite} kg) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmer == true && context.mounted) {
      final sauvegarde = await provider.supprimer(recolte.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sauvegarde
                ? 'Récolte supprimée'
                : 'La récolte est supprimée, mais la sauvegarde a échoué',
          ),
          backgroundColor: sauvegarde ? null : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des récoltes'),
        centerTitle: true,
      ),
      body: Consumer<RecoltesProvider>(
        builder: (context, provider, child) {
          final recoltes = provider.recoltes;

          if (recoltes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, size: 75, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'Aucune récolte enregistrée',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Ajoutez votre première récolte.'),
                ],
              ),
            );
          }

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const Icon(
                    Icons.inventory_2,
                    color: Colors.green,
                    size: 35,
                  ),
                  title: const Text('Quantité totale récoltée'),
                  subtitle: Text(
                    '${provider.quantiteTotale.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: recoltes.length,
                  itemBuilder: (context, index) {
                    final recolte = recoltes[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.agriculture, color: Colors.green),
                        ),
                        title: Text(
                          recolte.culture,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${recolte.nomZone}\n'
                          '${recolte.quantite} kg • '
                          '${recolte.dateRecolte.day}/'
                          '${recolte.dateRecolte.month}/'
                          '${recolte.dateRecolte.year}\n'
                          'Qualité : ${recolte.qualite}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<_ActionRecolte>(
                          onSelected: (action) {
                            if (action == _ActionRecolte.modifier) {
                              _ouvrirFormulaire(context, recolte: recolte);
                            } else {
                              _supprimer(context, provider, recolte);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: _ActionRecolte.modifier,
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Modifier'),
                              ),
                            ),
                            PopupMenuItem(
                              value: _ActionRecolte.supprimer,
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Supprimer'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ouvrirFormulaire(context),
        tooltip: 'Ajouter une récolte',
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum _ActionRecolte { modifier, supprimer }
