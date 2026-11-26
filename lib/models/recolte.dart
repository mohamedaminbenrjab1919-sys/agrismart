class Recolte {
  final String id;
  final String nomZone;
  final String culture;
  final double quantite;
  final DateTime dateRecolte;
  final String qualite;

  Recolte({
    required this.id,
    required this.nomZone,
    required this.culture,
    required this.quantite,
    required this.dateRecolte,
    required this.qualite,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nomZone': nomZone,
    'culture': culture,
    'quantite': quantite,
    'dateRecolte': dateRecolte.toIso8601String(),
    'qualite': qualite,
  };

  factory Recolte.fromJson(Map<String, dynamic> json) {
    return Recolte(
      id: json['id'] as String,
      nomZone: json['nomZone'] as String,
      culture: json['culture'] as String,
      quantite: (json['quantite'] as num).toDouble(),
      dateRecolte: DateTime.parse(json['dateRecolte'] as String),
      qualite: json['qualite'] as String,
    );
  }

  Recolte copyWith({
    String? id,
    String? nomZone,
    String? culture,
    double? quantite,
    DateTime? dateRecolte,
    String? qualite,
  }) {
    return Recolte(
      id: id ?? this.id,
      nomZone: nomZone ?? this.nomZone,
      culture: culture ?? this.culture,
      quantite: quantite ?? this.quantite,
      dateRecolte: dateRecolte ?? this.dateRecolte,
      qualite: qualite ?? this.qualite,
    );
  }
}
