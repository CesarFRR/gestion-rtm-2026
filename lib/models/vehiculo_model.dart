import 'package:cloud_firestore/cloud_firestore.dart';

class Vehiculo {
  final String id;
  final String placa;
  final String empresa;
  final String tipo; // 'Carro' o 'Moto'
  final DateTime? fechaMatricula;
  final DateTime? venceRTM;
  final DateTime? venceSOAT;
  final DateTime? venceBotiquin; // Puede ser nulo si es Moto
  final DateTime? venceExtintor; // Puede ser nulo si es Moto
  
  // URLs de fotos
  final String? fotoFrenteUrl;
  final String? fotoTraseraUrl;
  final String? fotoLateralDerechoUrl;
  final String? fotoLateralIzquierdoUrl;

  Vehiculo({
    required this.id,
    required this.placa,
    required this.empresa,
    required this.tipo,
    required this.fechaMatricula,
    required this.venceRTM,
    required this.venceSOAT,
    this.venceBotiquin,
    this.venceExtintor,
    this.fotoFrenteUrl,
    this.fotoTraseraUrl,
    this.fotoLateralDerechoUrl,
    this.fotoLateralIzquierdoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'placa': placa,
      'empresa': empresa,
      'tipo': tipo,
      'fechaMatricula': fechaMatricula != null ? Timestamp.fromDate(fechaMatricula!) : null,
      'venceRTM': venceRTM != null ? Timestamp.fromDate(venceRTM!) : null,
      'venceSOAT': venceSOAT != null ? Timestamp.fromDate(venceSOAT!) : null,
      'venceBotiquin': venceBotiquin != null ? Timestamp.fromDate(venceBotiquin!) : null,
      'venceExtintor': venceExtintor != null ? Timestamp.fromDate(venceExtintor!) : null,
      'fotoFrenteUrl': fotoFrenteUrl,
      'fotoTraseraUrl': fotoTraseraUrl,
      'fotoLateralDerechoUrl': fotoLateralDerechoUrl,
      'fotoLateralIzquierdoUrl': fotoLateralIzquierdoUrl,
    };
  }

  factory Vehiculo.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime? toDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      return null;
    }

    return Vehiculo(
      id: doc.id,
      placa: data['placa'] ?? '',
      empresa: data['empresa'] ?? '',
      tipo: data['tipo'] ?? 'Carro',
      fechaMatricula: toDateTime(data['fechaMatricula']),
      venceRTM: toDateTime(data['venceRTM']),
      venceSOAT: toDateTime(data['venceSOAT']),
      venceBotiquin: toDateTime(data['venceBotiquin']),
      venceExtintor: toDateTime(data['venceExtintor']),
      fotoFrenteUrl: data['fotoFrenteUrl'],
      fotoTraseraUrl: data['fotoTraseraUrl'],
      fotoLateralDerechoUrl: data['fotoLateralDerechoUrl'],
      fotoLateralIzquierdoUrl: data['fotoLateralIzquierdoUrl'],
    );
  }

  // Lógica de negocio (Getters)
  
  bool get tieneAlertaRoja {
    if (venceRTM == null) return false;
    final dias = venceRTM!.difference(DateTime.now()).inDays;
    return dias < 10;
  }
}
