import 'package:cloud_firestore/cloud_firestore.dart';

enum ClientType {
  persoanaFizica,
  persoanaJuridica;

  static ClientType fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'persoana_fizica':
      case 'persoanafizica':
        return ClientType.persoanaFizica;
      case 'persoana_juridica':
      case 'persoanajuridica':
        return ClientType.persoanaJuridica;
      default:
        return ClientType.persoanaFizica;
    }
  }

  @override
  String toString() {
    switch (this) {
      case ClientType.persoanaFizica:
        return 'persoana_fizica';
      case ClientType.persoanaJuridica:
        return 'persoana_juridica';
    }
  }

  String get displayName {
    switch (this) {
      case ClientType.persoanaFizica:
        return 'Persoană Fizică';
      case ClientType.persoanaJuridica:
        return 'Persoană Juridică';
    }
  }
}

class CompanyModel {
  final String id;
  final String name;
  final ClientType clientType;
  final String email;
  final String password;
  final String phone;
  final String city;
  final bool isActive;

  // Romanian invoicing fields (Persoană Juridică)
  final String? cui;
  final String? nrRegCom;
  final String? adresaSediu;
  final String? judet;
  final String? banca;
  final String? iban;

  CompanyModel({
    required this.id,
    required this.name,
    required this.clientType,
    required this.email,
    required this.password,
    this.phone = '',
    required this.city,
    required this.isActive,
    this.cui,
    this.nrRegCom,
    this.adresaSediu,
    this.judet,
    this.banca,
    this.iban,
  });

  bool get isPersoanaJuridica => clientType == ClientType.persoanaJuridica;

  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      clientType: ClientType.fromString(data['clientType'] as String? ?? 'persoana_fizica'),
      email: data['email'] as String? ?? '',
      password: data['password'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      city: data['city'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      cui: data['cui'] as String?,
      nrRegCom: data['nrRegCom'] as String?,
      adresaSediu: data['adresaSediu'] as String?,
      judet: data['judet'] as String?,
      banca: data['banca'] as String?,
      iban: data['iban'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'clientType': clientType.toString(),
      'email': email,
      'password': password,
      'phone': phone,
      'city': city,
      'isActive': isActive,
      if (cui != null) 'cui': cui,
      if (nrRegCom != null) 'nrRegCom': nrRegCom,
      if (adresaSediu != null) 'adresaSediu': adresaSediu,
      if (judet != null) 'judet': judet,
      if (banca != null) 'banca': banca,
      if (iban != null) 'iban': iban,
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map) {
    return CompanyModel(
      id: map['id'] as String,
      name: map['name'] as String,
      clientType: ClientType.fromString(map['clientType'] as String? ?? 'persoana_fizica'),
      email: map['email'] as String,
      password: map['password'] as String,
      phone: map['phone'] as String? ?? '',
      city: map['city'] as String,
      isActive: map['isActive'] as bool,
      cui: map['cui'] as String?,
      nrRegCom: map['nrRegCom'] as String?,
      adresaSediu: map['adresaSediu'] as String?,
      judet: map['judet'] as String?,
      banca: map['banca'] as String?,
      iban: map['iban'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientType': clientType.toString(),
      'email': email,
      'password': password,
      'phone': phone,
      'city': city,
      'isActive': isActive,
      'cui': cui,
      'nrRegCom': nrRegCom,
      'adresaSediu': adresaSediu,
      'judet': judet,
      'banca': banca,
      'iban': iban,
    };
  }

  CompanyModel copyWith({
    String? id,
    String? name,
    ClientType? clientType,
    String? email,
    String? password,
    String? phone,
    String? city,
    bool? isActive,
    String? cui,
    String? nrRegCom,
    String? adresaSediu,
    String? judet,
    String? banca,
    String? iban,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      clientType: clientType ?? this.clientType,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
      cui: cui ?? this.cui,
      nrRegCom: nrRegCom ?? this.nrRegCom,
      adresaSediu: adresaSediu ?? this.adresaSediu,
      judet: judet ?? this.judet,
      banca: banca ?? this.banca,
      iban: iban ?? this.iban,
    );
  }
}
