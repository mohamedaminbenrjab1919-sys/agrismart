import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrismart/services/face_recognition_service.dart';

enum ModeScanVisage {
  inscription,
  connexion,
}

class FaceScanPage extends StatefulWidget {
  final ModeScanVisage mode;
  final List<double>? embeddingReference;

  const FaceScanPage({
    super.key,
    required this.mode,
    this.embeddingReference,
  });

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  final ImagePicker _picker = ImagePicker();
  final FaceRecognitionService _faceService = FaceRecognitionService();

  File? _imageFichier;
  bool _enTraitement = false;
  String? _messageErreur;
  String _statut = 'Prenez une photo claire de votre visage';

  @override
  void dispose() {
    _faceService.fermer();
    super.dispose();
  }

  Future<void> _capturerEtAnalyser(ImageSource source) async {
    setState(() {
      _messageErreur = null;
      _enTraitement = true;
      _statut = 'Ouverture de la caméra...';
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
      );

      if (photo == null) {
        if (!mounted) return;
        setState(() {
          _enTraitement = false;
          _statut = 'Capture annulée';
        });
        return;
      }

      final fichier = File(photo.path);
      setState(() {
        _imageFichier = fichier;
        _statut = 'Analyse du visage en cours...';
      });

      final embedding =
      await _faceService.extraireEmbeddingDepuisFichier(fichier.path);

      if (!mounted) return;

      if (widget.mode == ModeScanVisage.inscription) {
        Navigator.pop<List<double>>(context, embedding);
        return;
      }

      final reference = widget.embeddingReference;
      if (reference == null || reference.isEmpty) {
        setState(() {
          _enTraitement = false;
          _messageErreur = 'Aucun visage de référence trouvé.';
          _statut = 'Échec de la vérification';
        });
        return;
      }

      final score = _faceService.similariteCosinus(embedding, reference);
      final reconnu = _faceService.estMemeVisage(
        embedding,
        reference,
        seuil: 0.65,
      );

      if (reconnu) {
        Navigator.pop<bool>(context, true);
      } else {
        setState(() {
          _enTraitement = false;
          _messageErreur =
          'Visage non reconnu (similarité : ${(score * 100).toStringAsFixed(1)}%). Réessayez avec un meilleur éclairage.';
          _statut = 'Échec de reconnaissance';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enTraitement = false;
        _messageErreur = e.toString().replaceFirst('Exception: ', '');
        _statut = 'Erreur lors du scan';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final estInscription = widget.mode == ModeScanVisage.inscription;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          estInscription
              ? 'Enregistrer mon visage'
              : 'Connexion par visage',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 220,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(120),
                    border: Border.all(
                      color: _messageErreur != null
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageFichier != null
                      ? Image.file(
                    _imageFichier!,
                    fit: BoxFit.cover,
                  )
                      : const Icon(
                    Icons.face_retouching_natural,
                    size: 96,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _statut,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_messageErreur != null) ...[
                const SizedBox(height: 12),
                Text(
                  _messageErreur!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (_enTraitement)
                const Center(child: CircularProgressIndicator())
              else ...[
                FilledButton.icon(
                  onPressed: () => _capturerEtAnalyser(ImageSource.camera),
                  icon: const Icon(Icons.camera_front),
                  label: const Text('Scanner avec la caméra'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _capturerEtAnalyser(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choisir une photo'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}