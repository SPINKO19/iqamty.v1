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
  final String? bloc;
  final String? chambre;

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
    this.bloc,
    this.chambre,
  });

  factory Student.fromJson(Map<String, dynamic> json, {String? residence, String? bloc, String? chambre}) {
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
      residence: residence,
      bloc: bloc,
      chambre: chambre,
    );
  }
}
