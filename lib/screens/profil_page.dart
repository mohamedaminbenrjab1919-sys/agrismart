import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/utilisateur.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/providers/auth_provider.dart';
import 'package:agrismart/screens/a_propos_page.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  Future<void> _modifierNom(
      BuildContext context,
      Utilisateur? utilisateur,
      ) async {
    final ctrl = TextEditingController(text: utilisateur?.nom ?? '');
    final formKey = GlobalKey<FormState>();

    final nouveauNom = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nom complet / Exploitation',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if ((val ?? '').trim().length < 2) {
                return '2 caractères minimum';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    ctrl.dispose();
    if (nouveauNom == null || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.mettreAJourNom(nouveauNom);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Nom mis à jour avec succès' : (auth.erreur ?? 'Erreur'),
        ),
      ),
    );
  }

  Future<void> _confirmerDeconnexion(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;
    await context.read<AuthProvider>().deconnexion();
  }

  Future<void> _confirmerSuppressionCompte(BuildContext context) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte ?'),
        content: const Text(
          'Cette action est irréversible et supprimera votre compte d\'authentification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.supprimerCompte();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.erreur ?? 'Impossible de supprimer le compte'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final texte = Theme.of(context).textTheme;
    final nombreZones = context.select<ZonesProvider, int>((p) => p.nombre);
    final utilisateur = context.select<AuthProvider, Utilisateur?>(
          (a) => a.utilisateur,
    );
    final occupe = context.select<AuthProvider, bool>((a) => a.occupe);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const Center(
            child: CircleAvatar(
              radius: 40,
              child: Icon(Icons.agriculture, size: 40),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              utilisateur?.nomAffiche ?? 'Exploitation AgriSmart',
              style: texte.titleLarge,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              utilisateur?.email ?? '',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Modifier le nom'),
            trailing: const Icon(Icons.chevron_right),
            onTap: occupe ? null : () => _modifierNom(context, utilisateur),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.grass),
            title: const Text('Zones suivies'),
            trailing: Text('$nombreZones'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AProposPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
            onTap: occupe ? null : () => _confirmerDeconnexion(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Supprimer mon compte',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: occupe ? null : () => _confirmerSuppressionCompte(context),
          ),
        ],
      ),
    );
  }
}