import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  static const String _modelAssetPath = 'assets/models/mobile_face_net.tflite';

  Interpreter? _interpreter;
  late final FaceDetector _faceDetector;

  int _inputHeight = 112;
  int _inputWidth = 112;
  int _embeddingSize = 192;

  FaceRecognitionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: false,
        enableClassification: true, // yeux ouverts / sourire
        minFaceSize: 0.15,
      ),
    );
  }

  bool get estPret => _interpreter != null;

  Future<void> initialiser() async {
    if (_interpreter != null) return;

    _interpreter = await Interpreter.fromAsset(_modelAssetPath);
    final inputShape = _interpreter!.getInputTensor(0).shape;
    final outputShape = _interpreter!.getOutputTensor(0).shape;

    if (inputShape.length >= 3) {
      _inputHeight = inputShape[1];
      _inputWidth = inputShape[2];
    }
    if (outputShape.isNotEmpty) {
      _embeddingSize = outputShape.last;
    }
  }

  /// Extrait le vecteur facial (embedding) depuis un chemin d'image (File).
  Future<List<double>> extraireEmbeddingDepuisFichier(String imagePath) async {
    await initialiser();

    final inputImage = InputImage.fromFilePath(imagePath);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      throw Exception('Aucun visage détecté sur la photo.');
    }
    if (faces.length > 1) {
      throw Exception('Plusieurs visages détectés. Gardez un seul visage.');
    }

    final face = faces.first;

    // Vérification simple de vivacité (yeux ouverts si disponible)
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;
    if (leftEye != null && rightEye != null && leftEye < 0.25 && rightEye < 0.25) {
      throw Exception('Veuillez garder les yeux ouverts.');
    }

    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception("Impossible de lire l'image.");
    }

    final oriented = img.bakeOrientation(decoded);
    final box = face.boundingBox;

    // Marge légère autour du visage + bornes sûres
    final padX = (box.width * 0.12).round();
    final padY = (box.height * 0.12).round();

    final left = max(0, box.left.round() - padX);
    final top = max(0, box.top.round() - padY);
    final right = min(oriented.width, box.right.round() + padX);
    final bottom = min(oriented.height, box.bottom.round() + padY);

    final cropW = right - left;
    final cropH = bottom - top;
    if (cropW <= 10 || cropH <= 10) {
      throw Exception('Visage trop petit ou mal cadré.');
    }

    final cropped = img.copyCrop(
      oriented,
      x: left,
      y: top,
      width: cropW,
      height: cropH,
    );

    final resized = img.copyResize(
      cropped,
      width: _inputWidth,
      height: _inputHeight,
      interpolation: img.Interpolation.linear,
    );

    // Préparation input [1, H, W, 3] normalisé [-1, 1]
    final inputBuffer = Float32List(1 * _inputHeight * _inputWidth * 3);
    int idx = 0;
    for (int y = 0; y < _inputHeight; y++) {
      for (int x = 0; x < _inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        inputBuffer[idx++] = (pixel.r - 127.5) / 128.0;
        inputBuffer[idx++] = (pixel.g - 127.5) / 128.0;
        inputBuffer[idx++] = (pixel.b - 127.5) / 128.0;
      }
    }

    final reshapedInput = inputBuffer.reshape([1, _inputHeight, _inputWidth, 3]);
    final outputBuffer = List.generate(
      1,
          (_) => List<double>.filled(_embeddingSize, 0.0),
    );

    _interpreter!.run(reshapedInput, outputBuffer);

    return _normaliserL2(outputBuffer.first);
  }

  List<double> _normaliserL2(List<double> vecteur) {
    double sommeCarres = 0.0;
    for (final v in vecteur) {
      sommeCarres += v * v;
    }
    final norme = sqrt(sommeCarres);
    if (norme == 0) return vecteur;
    return vecteur.map((v) => v / norme).toList();
  }

  /// Similarité cosinus entre [-1, 1] (plus proche de 1.0 = même visage).
  double similariteCosinus(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return -1.0;
    final normA = _normaliserL2(a);
    final normB = _normaliserL2(b);
    double dot = 0.0;
    for (int i = 0; i < normA.length; i++) {
      dot += normA[i] * normB[i];
    }
    return dot;
  }

  bool estMemeVisage(
      List<double> embedding1,
      List<double> embedding2, {
        double seuil = 0.65,
      }) {
    return similariteCosinus(embedding1, embedding2) >= seuil;
  }

  void fermer() {
    _interpreter?.close();
    _interpreter = null;
    _faceDetector.close();
  }
}