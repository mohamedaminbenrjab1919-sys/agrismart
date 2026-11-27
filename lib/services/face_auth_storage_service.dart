import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FaceAuthStorageService {
  static const String _cleEmbedding = 'face_rec_embedding_v1';
  static const String _cleEmail = 'face_rec_email_v1';

  Future<void> enregistrerVisage({
    required String email,
    required List<double> embedding,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleEmail, email.trim().toLowerCase());
    await prefs.setString(_cleEmbedding, jsonEncode(embedding));
  }

  Future<String?> lireEmailAssocie() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_cleEmail);
    if (email == null || email.trim().isEmpty) return null;
    return email;
  }

  Future<List<double>?> lireEmbeddingAssocie() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cleEmbedding);
    if (raw == null || raw.isEmpty) return null;

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => (e as num).toDouble()).toList();
  }

  Future<bool> aUnVisageEnregistre() async {
    final email = await lireEmailAssocie();
    final emb = await lireEmbeddingAssocie();
    return email != null && emb != null && emb.isNotEmpty;
  }

  Future<void> supprimerVisage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cleEmail);
    await prefs.remove(_cleEmbedding);
  }
}