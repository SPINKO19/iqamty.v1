class Student {
  final int? id;
  final String? nin;
  final String? matricule;
  final String? nomAr;
  final String? prenomAr;
  final String? nomFr;
  final String? prenomFr;
  final String? moyenneBac;
  final String? photoEtudiant;
  final String? photo;
  final String? photoBase64;
  final String? dateNaissance;
  final String? residence;
  final String? residenceId; // Added for multi-tenancy
  final String? bloc;
  final String? chambre;
  final String? role;
  final bool isBanned;

  Student({
    this.id,
    this.nin,
    this.matricule,
    this.nomAr,
    this.prenomAr,
    this.nomFr,
    this.prenomFr,
    this.moyenneBac,
    this.photoEtudiant,
    this.photo,
    this.photoBase64,
    this.dateNaissance,
    this.residence,
    this.residenceId,
    this.bloc,
    this.chambre,
    this.role,
    this.isBanned = false,
  });

  factory Student.fromJson(Map<String, dynamic> json, {String? residence, String? residenceId, String? bloc, String? chambre}) {
    return Student(
      id: json['Id'] ?? json['id'],
      nin: json['Nin'] ?? json['nin'],
      matricule: json['Matricule']?.toString() ?? json['matricule']?.toString(), // Ensure string conversion if API returns Double
      nomAr: json['nomAr'] ?? json['individuNomArabe'] ?? json['nomArabe'],
      prenomAr: json['prenomAr'] ?? json['individuPrenomArabe'] ?? json['prenomArabe'],
      nomFr: json['nomFr'] ?? json['individuNomLatin'] ?? json['nomLatin'],
      prenomFr: json['prenomFr'] ?? json['individuPrenomLatin'] ?? json['prenomLatin'],
      moyenneBac: json['moyenneBac']?.toString(),
      photoEtudiant: json['photoEtudiant'],
      photo: json['photo'],
      photoBase64: json['photoBase64'],
      dateNaissance: json['dateNaissance'] ?? json['individuDateNaissance'],
      residence: residence ?? json['residence'],
      residenceId: residenceId ?? json['residenceId'],
      bloc: bloc ?? json['bloc'],
      chambre: chambre ?? json['chambre'],
      role: json['role'] as String?,
      isBanned: json['isBanned'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (nin != null) 'nin': nin,
      if (matricule != null) 'matricule': matricule,
      if (nomAr != null) 'nomAr': nomAr,
      if (prenomAr != null) 'prenomAr': prenomAr,
      if (nomFr != null) 'nomFr': nomFr,
      if (prenomFr != null) 'prenomFr': prenomFr,
      if (moyenneBac != null) 'moyenneBac': moyenneBac,
      if (photoEtudiant != null) 'photoEtudiant': photoEtudiant,
      if (photo != null) 'photo': photo,
      if (photoBase64 != null) 'photoBase64': photoBase64,
      if (dateNaissance != null) 'dateNaissance': dateNaissance,
      if (residence != null) 'residence': residence,
      if (residenceId != null) 'residenceId': residenceId,
      if (bloc != null) 'bloc': bloc,
      if (chambre != null) 'chambre': chambre,
      if (role != null) 'role': role,
      'isBanned': isBanned,
    };
  }
}

