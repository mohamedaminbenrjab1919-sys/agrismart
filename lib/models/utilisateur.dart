class Utilisateur {
  final String uid;
  final String email;
  final String? nom;

  const Utilisateur({
    required this.uid,
    required this.email,
    this.nom,
  });

  String get nomAffiche {
    final n = (nom ?? '').trim();
    if (n.isNotEmpty) return n;
    return email.split('@').first;
  }
}