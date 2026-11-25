import 'package:flutter/material.dart';
import 'package:agrismart/models/zone.dart';

class ZoneForm extends StatefulWidget {
  final Zone? zone;
  final List<String> nomsExistants;
  final void Function(Zone) onEnregistrer;

  const ZoneForm({
    super.key,
    this.zone,
    required this.nomsExistants,
    required this.onEnregistrer,
  });

  @override
  State<ZoneForm> createState() => _ZoneFormState();
}

class _ZoneFormState extends State<ZoneForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _cultureCtrl = TextEditingController();
  final _humiditeCtrl = TextEditingController();
  final _seuilCtrl = TextEditingController();

  bool get _modeEdition => widget.zone != null;

  @override
  void initState() {
    super.initState();
    final zone = widget.zone;
    if (zone != null) {
      _nomCtrl.text = zone.nom;
      _cultureCtrl.text = zone.culture;
      _seuilCtrl.text = _formater(zone.seuil);
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _cultureCtrl.dispose();
    _humiditeCtrl.dispose();
    _seuilCtrl.dispose();
    super.dispose();
  }

  double? _lireNombre(String? texte) {
    return double.tryParse((texte ?? '').trim().replaceAll(',', '.'));
  }

  String _formater(double n) {
    return n % 1 == 0 ? n.toStringAsFixed(0) : n.toString();
  }

  String? _validerNom(String? valeur) {
    if (valeur == null || valeur.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    final nomSaisi = valeur.trim().toLowerCase();
    if (widget.nomsExistants.any((n) => n.toLowerCase() == nomSaisi)) {
      return 'Ce nom existe déjà';
    }
    return null;
  }

  String? _validerCulture(String? valeur) {
    if (valeur == null || valeur.trim().length < 2) {
      return 'La culture doit contenir au moins 2 caractères';
    }
    return null;
  }

  String? _validerPourcentage(String? valeur) {
    final n = _lireNombre(valeur);
    if (n == null) {
      return 'Veuillez saisir un nombre valide';
    }
    if (n < 0 || n > 100) {
      return 'La valeur doit être entre 0 et 100';
    }
    return null;
  }

  void _soumettre() {
    if (_formKey.currentState!.validate()) {
      final ancienne = widget.zone;
      final humidite = _modeEdition
          ? (ancienne?.humidite ?? 50.0)
          : (_lireNombre(_humiditeCtrl.text) ?? 50.0);
      final nouvelle = Zone(
        _nomCtrl.text.trim(),
        _cultureCtrl.text.trim(),
        humidite,
        _lireNombre(_seuilCtrl.text) ?? 35.0,
        vanneOuverte: ancienne?.vanneOuverte ?? false,
      );
      widget.onEnregistrer(nouvelle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Le titre a été retiré d'ici pour être mis dans l'AppBar de ZoneFormPage
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la zone',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: _validerNom,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cultureCtrl,
              decoration: const InputDecoration(
                labelText: 'Culture',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: _validerCulture,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!_modeEdition) ...[
                  Expanded(
                    child: TextFormField(
                      controller: _humiditeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Humidité (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      validator: _validerPourcentage,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextFormField(
                    controller: _seuilCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Seuil (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    validator: _validerPourcentage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _soumettre,
              child: Text(_modeEdition ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}