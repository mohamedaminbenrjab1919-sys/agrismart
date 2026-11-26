import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:agrismart/models/diagnostic_plante.dart';
import 'package:agrismart/models/zone.dart';
import 'package:agrismart/providers/zones_provider.dart';
import 'package:agrismart/services/plante_diagnostic_service.dart';

class ScannerPlantePage extends StatefulWidget {
  const ScannerPlantePage({super.key});

  @override
  State<ScannerPlantePage> createState() => _ScannerPlantePageState();
}

class _ScannerPlantePageState extends State<ScannerPlantePage> {
  final _picker = ImagePicker();
  final _service = PlanteDiagnosticService();

  File? _image;
  DiagnosticPlante? _diagnostic;
  String? _cultureSelectionnee;
  bool _chargement = false;
  String? _erreur;

  Future<void> _capturerImage(ImageSource source) async {
    setState(() => _erreur = null);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (picked == null) return;

      final fichier = File(picked.path);
      setState(() {
        _image = fichier;
        _chargement = true;
      });

      final resultat = await _service.analyserImage(
        fichier,
        cultureForcee: _cultureSelectionnee,
      );

      if (!mounted) return;
      setState(() {
        _diagnostic = resultat;
        _cultureSelectionnee = resultat.nomPlante;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = "Impossible d'analyser l'image : $e";
      });
    }
  }

  Future<void> _reanalyserAvecCulture(String? nouvelleCulture) async {
    setState(() => _cultureSelectionnee = nouvelleCulture);
    if (_image == null) return;

    setState(() => _chargement = true);
    final resultat = await _service.analyserImage(
      _image!,
      cultureForcee: nouvelleCulture,
    );
    if (!mounted) return;
    setState(() {
      _diagnostic = resultat;
      _chargement = false;
    });
  }

  void _ajouterAuxZones(DiagnosticPlante diag) {
    final zonesProvider = context.read<ZonesProvider>();
    final nomsExistants = zonesProvider.noms();
    var nomZone = diag.nomPlante.split('(').first.trim();
    var compteur = 2;
    while (nomsExistants.contains(nomZone)) {
      nomZone = '${diag.nomPlante.split('(').first.trim()} $compteur';
      compteur++;
    }

    final humiditeInitiale = diag.estSaine
        ? ((diag.humiditeIdealeMin + diag.humiditeIdealeMax) / 2).roundToDouble()
        : (diag.humiditeIdealeMin - 10).clamp(15, 90).toDouble();

    zonesProvider.ajouter(
      Zone(
        nom: nomZone,
        culture: diag.nomPlante,
        humidite: humiditeInitiale,
        seuil: diag.humiditeIdealeMin.toDouble(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Zone "$nomZone" ajoutée aux parcelles suivies !'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.inversePrimary,
        title: const Text('Diagnostic Plante (IA)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Zone d'aperçu photo
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: _image != null
                ? Image.file(_image!, fit: BoxFit.cover, width: double.infinity)
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.eco_outlined, size: 56, color: colors.primary),
                const SizedBox(height: 8),
                Text(
                  'Photographiez un arbre ou une plante',
                  style: texte.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Analyse ML Kit : espèce, eau nécessaire et état de santé',
                  style: texte.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Boutons Caméra & Galerie
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _chargement
                      ? null
                      : () => _capturerImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Caméra'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _chargement
                      ? null
                      : () => _capturerImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galerie'),
                ),
              ),
            ],
          ),

          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(_erreur!, style: TextStyle(color: colors.error)),
          ],

          if (_chargement) ...[
            const SizedBox(height: 32),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            const Center(child: Text('Analyse de la plante en cours...')),
          ],

          if (!_chargement && _diagnostic != null) ...[
            const SizedBox(height: 20),

            // Sélecteur pour affiner l'espèce si besoin
            DropdownButtonFormField<String>(
              value: _cultureSelectionnee,
              decoration: const InputDecoration(
                labelText: 'Espèce identifiée (modifiable)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.park_outlined),
              ),
              items: PlanteDiagnosticService.fichesDisponibles
                  .map(
                    (f) => DropdownMenuItem(
                  value: f.nom,
                  child: Text(f.nom),
                ),
              )
                  .toList(),
              onChanged: _reanalyserAvecCulture,
            ),
            const SizedBox(height: 16),

            // 1. Carte État de santé
            Card(
              color: _diagnostic!.estSaine
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _diagnostic!.estSaine
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color:
                      _diagnostic!.estSaine ? Colors.green : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _diagnostic!.etatSante,
                            style: texte.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_diagnostic!.messageSante),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Carte Besoins en Eau & Irrigation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Besoins en eau & Arrosage',
                          style: texte.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _ligneInfo('Quantité d’eau', _diagnostic!.quantiteEau),
                    _ligneInfo('Quand arroser', _diagnostic!.frequenceArrosage),
                    _ligneInfo('Meilleur moment', _diagnostic!.momentIdeal),
                    _ligneInfo(
                      'Humidité idéale',
                      '${_diagnostic!.humiditeIdealeMin}% – ${_diagnostic!.humiditeIdealeMax}%',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Carte Caractéristiques & Conseils
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Caractéristiques & Conseils',
                          style: texte.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _ligneInfo('Catégorie', _diagnostic!.categorie),
                    _ligneInfo('Exposition', _diagnostic!.expositionSoleil),
                    _ligneInfo('Type de sol', _diagnostic!.typeSol),
                    const SizedBox(height: 8),
                    Text(
                      'Recommandations :',
                      style: texte.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ..._diagnostic!.conseils.map(
                          (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(c)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: _diagnostic!.labelsDetectes
                          .map(
                            (l) => Chip(
                          label: Text(l, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bouton d'intégration avec le reste de l'app
            FilledButton.icon(
              onPressed: () => _ajouterAuxZones(_diagnostic!),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Ajouter cette plante aux zones suivies'),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _ligneInfo(String titre, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$titre :',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valeur)),
        ],
      ),
    );
  }
}