class DiagnosticPlante {
  final String nomPlante;
  final String categorie;
  final double confiance;
  final String frequenceArrosage;
  final String momentIdeal;
  final String quantiteEau;
  final int humiditeIdealeMin;
  final int humiditeIdealeMax;
  final String expositionSoleil;
  final String typeSol;
  final String etatSante; // 'Bon état', 'Attention requise', 'Stress hydrique'
  final bool estSaine;
  final String messageSante;
  final List<String> conseils;
  final List<String> labelsDetectes;

  const DiagnosticPlante({
    required this.nomPlante,
    required this.categorie,
    required this.confiance,
    required this.frequenceArrosage,
    required this.momentIdeal,
    required this.quantiteEau,
    required this.humiditeIdealeMin,
    required this.humiditeIdealeMax,
    required this.expositionSoleil,
    required this.typeSol,
    required this.etatSante,
    required this.estSaine,
    required this.messageSante,
    required this.conseils,
    required this.labelsDetectes,
  });
}