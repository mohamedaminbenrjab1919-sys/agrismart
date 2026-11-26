import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:agrismart/models/recolte.dart';
import 'package:agrismart/providers/recoltes_provider.dart';
import 'package:agrismart/providers/zones_provider.dart';

class RecolteFormPage extends StatefulWidget {
  final Recolte? recolte;

  const RecolteFormPage({super.key, this.recolte});

  @override
  State<RecolteFormPage> createState() => _RecolteFormPageState();
}

class _RecolteFormPageState extends State<RecolteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteController = TextEditingController();

  String? _zoneSelectionnee;
  String _qualite = 'Bonne';
  DateTime _dateRecolte = DateTime.now();

  @override
  void initState() {
    super.initState();
    final recolte = widget.recolte;
    if (recolte != null) {
      _zoneSelectionnee = recolte.nomZone;
      _quantiteController.text = recolte.quantite.toStringAsFixed(
        recolte.quantite == recolte.quantite.roundToDouble() ? 0 : 1,
      );
      _qualite = recolte.qualite;
      _dateRecolte = recolte.dateRecolte;
    }
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateRecolte,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _dateRecolte = date;
      });
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final zones = context.read<ZonesProvider>().zones;

    final zone = zones.firstWhere((z) => z.nom == _zoneSelectionnee);

    final recolte = Recolte(
      id:
          widget.recolte?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      nomZone: zone.nom,
      culture: zone.culture,
      quantite: double.parse(_quantiteController.text.trim()),
      dateRecolte: _dateRecolte,
      qualite: _qualite,
    );

    final provider = context.read<RecoltesProvider>();
    bool sauvegarde;
    if (widget.recolte == null) {
      sauvegarde = await provider.ajouter(recolte);
    } else {
      sauvegarde = await provider.modifier(widget.recolte!, recolte);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sauvegarde
              ? (widget.recolte == null
                    ? 'Récolte enregistrée avec succès !'
                    : 'Récolte modifiée avec succès !')
              : 'La modification est visible, mais n’a pas pu être sauvegardée.',
        ),
        backgroundColor: sauvegarde ? Colors.green : Colors.orange,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final zones = context.watch<ZonesProvider>().zones;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.recolte == null ? 'Nouvelle récolte' : 'Modifier la récolte',
        ),
        centerTitle: true,
      ),
      body: zones.isEmpty
          ? const Center(child: Text('Ajoutez d’abord une zone agricole.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.agriculture,
                      size: 65,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Informations de la récolte',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: _zoneSelectionnee,
                      decoration: const InputDecoration(
                        labelText: 'Zone agricole',
                        prefixIcon: Icon(Icons.landscape),
                        border: OutlineInputBorder(),
                      ),
                      items: zones.map((zone) {
                        return DropdownMenuItem<String>(
                          value: zone.nom,
                          child: Text(zone.nom),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _zoneSelectionnee = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez choisir une zone';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _quantiteController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Quantité récoltée (kg)',
                        prefixIcon: Icon(Icons.scale),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir la quantité';
                        }

                        final quantite = double.tryParse(
                          value.trim().replaceAll(',', '.'),
                        );

                        if (quantite == null || quantite <= 0) {
                          return 'Saisissez une quantité valide';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Date de récolte',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    OutlinedButton.icon(
                      onPressed: _choisirDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        '${_dateRecolte.day}/'
                        '${_dateRecolte.month}/'
                        '${_dateRecolte.year}',
                      ),
                    ),

                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      initialValue: _qualite,
                      decoration: const InputDecoration(
                        labelText: 'Qualité du produit',
                        prefixIcon: Icon(Icons.star),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Excellente',
                          child: Text('Excellente'),
                        ),
                        DropdownMenuItem(value: 'Bonne', child: Text('Bonne')),
                        DropdownMenuItem(
                          value: 'Moyenne',
                          child: Text('Moyenne'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _qualite = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _enregistrer,
                        icon: const Icon(Icons.save),
                        label: const Text('Enregistrer la récolte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
